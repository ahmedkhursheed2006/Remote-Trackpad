import socket
import pyautogui
import threading
from pynput.mouse import Controller, Button

# Initialize mouse controller
mouse = Controller()

# Server Configuration
UDP_IP = "0.0.0.0"
UDP_PORT = 6000
DISCOVERY_PORT = 6001

# Identification
SERVER_NAME = socket.gethostname()

# Disable failsafe
pyautogui.FAILSAFE = False

# Screen resolution
screen_width, screen_height = pyautogui.size()

# --- Advanced Smoothing State (Exponential Moving Average) ---
# Current smoothed positions
curr_smoothed_x, curr_smoothed_y = mouse.position
# Smoothing factor (0.0 to 1.0). 
# Lower = smoother/liquid but more lag. Higher = snappy but jittery.
# 0.25 is usually the "sweet spot" for a liquid feel.
SMOOTHING_FACTOR = 0.25

def smooth_position(target_x, target_y):
    """
    Applies Exponential Smoothing to the coordinates.
    Formula: Smooth = (Target * Alpha) + (PreviousSmooth * (1 - Alpha))
    """
    global curr_smoothed_x, curr_smoothed_y
    
    curr_smoothed_x = (target_x * SMOOTHING_FACTOR) + (curr_smoothed_x * (1.0 - SMOOTHING_FACTOR))
    curr_smoothed_y = (target_y * SMOOTHING_FACTOR) + (curr_smoothed_y * (1.0 - SMOOTHING_FACTOR))
    
    return curr_smoothed_x, curr_smoothed_y

def discovery_listener():
    discovery_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    discovery_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    discovery_sock.bind((UDP_IP, DISCOVERY_PORT))
    while True:
        try:
            data, addr = discovery_sock.recvfrom(1024)
            if data.decode('utf-8') == "DISCOVERY_REQUEST":
                response = f"DISCOVERY_RESPONSE:{SERVER_NAME}"
                discovery_sock.sendto(response.encode('utf-8'), addr)
        except:
            pass

def get_local_ip():
    try:
        # Create a temporary socket to determine the local network interface IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "127.0.0.1"

def start_server():
    global curr_smoothed_x, curr_smoothed_y
    threading.Thread(target=discovery_listener, daemon=True).start()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    
    local_ip = get_local_ip()
    print(f"--- Remote Trackpad Server (Liquid Motion Enabled) ---")
    print(f"Server Name: {SERVER_NAME}")
    print(f"Local IP:    {local_ip}")
    print(f"Port:        {UDP_PORT}")
    print(f"------------------------------------------------------")
    
    is_drawing = False

    while True:
        try:
            data, addr = sock.recvfrom(1024)
            message = data.decode('utf-8')
            parts = message.split(',')
            
            if len(parts) >= 4:
                x_val = float(parts[0])
                y_val = float(parts[1])
                action_type = parts[2]
                mode = parts[3]
                
                # Update click state
                if action_type == 'down' and not is_drawing:
                    mouse.press(Button.left)
                    is_drawing = True
                elif action_type == 'up' and is_drawing:
                    mouse.release(Button.left)
                    is_drawing = False
                elif action_type == 'right_click':
                    mouse.click(Button.right)

                # --- Motion Calculation ---
                if mode == 'tablet':
                    # Absolute mapping
                    target_x = x_val * screen_width
                    target_y = y_val * screen_height
                else:
                    # Relative mapping (Trackpad)
                    # We apply the delta to our current smoothed position
                    target_x = curr_smoothed_x + x_val
                    target_y = curr_smoothed_y + y_val
                
                # Apply the "Liquid" filter
                final_x, final_y = smooth_position(target_x, target_y)
                
                # Constraint
                final_x = max(0, min(screen_width, final_x))
                final_y = max(0, min(screen_height, final_y))
                
                # Move the mouse
                mouse.position = (final_x, final_y)
                
        except Exception as e:
            print(f"Error: {e}")

if __name__ == '__main__':
    # Initial sync with OS mouse position
    curr_smoothed_x, curr_smoothed_y = mouse.position
    try:
        start_server()
    except KeyboardInterrupt:
        pass
