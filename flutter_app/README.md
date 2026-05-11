# Liquid Trackpad 📱💻

**Liquid Trackpad** is a professional-grade remote input system that transforms your mobile device into a high-performance trackpad and drawing tablet for your desktop. Built with Flutter and Python, it features ultra-smooth "liquid" motion and low-latency UDP communication.

---

## ✨ Key Features

- **Liquid Motion Engine**: Uses Exponential Moving Average (EMA) smoothing for a fluid, natural cursor feel.
- **Dual Mode Support**:
    - **Trackpad Mode**: Standard relative movement with adjustable sensitivity.
    - **Tablet Mode**: Absolute 1:1 mapping of your phone screen to your desktop monitor.
- **Smart Dragging**: A dedicated "Hold to Drag" system for reliable window management and digital drawing.
- **Auto-Discovery**: No need to type IP addresses. The app automatically scans your Wi-Fi and lists available laptops.
- **Right Click Support**: Dedicated right-click button for full mouse functionality.
- **Premium Aesthetics**: Sleek dark-mode UI with custom branding and a native splash screen.

---

## 🚀 Quick Start Guide

### 1. Preparation
- Ensure both your **Mobile Phone** and **Laptop** are connected to the **same Wi-Fi network**.

### 2. Desktop Setup (The Receiver)
- Navigate to the `python_server` folder.
- Run the server:
  ```bash
  python server.py
  ```
  *(Or run the bundled `RemoteTrackpad.exe` if you have built it).*

### 3. Mobile Setup (The Controller)
- Install the `app-release.apk` on your Android device.
- Open the app. It will automatically search for your laptop.
- Select your laptop from the list, and you're ready to go!

---

## 🛠️ Tech Stack

- **Client**: Flutter (Dart) - Low-latency input handling via raw `Listener` widgets.
- **Server**: Python - High-precision mouse control via `pynput` and `pyautogui`.
- **Protocol**: UDP (User Datagram Protocol) for near-zero latency communication.

---

## 📦 How to Build for Release

### Android APK
Inside the `flutter_app` directory:
```powershell
flutter build apk --release
```

### Windows EXE
Inside the `python_server` directory:
```powershell
pip install pyinstaller
pyinstaller --onefile --windowed --name "RemoteTrackpad" server.py
```

---

*Created with ❤️ for digital artists and power users.*
