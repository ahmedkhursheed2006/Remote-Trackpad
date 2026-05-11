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

### Android Variations
Inside the `flutter_app` directory:

**1. Build All Variations (Fat APKs):**
```powershell
flutter build apk --release
```

**2. Build Specific Edition (e.g., Pro):**
```powershell
flutter build apk --flavor pro --release
```

**3. Build Split APKs (Architecture Specific):**
```powershell
flutter build apk --release --split-per-abi
```
#### Which file should I use?
*   **`app-armeabi-v7a-release.apk` (32-bit)**: 
    *   **Best for**: Older phones (Android 4.4 to 7.1) and low-end modern budget devices.
    *   **Compatibility**: Works on almost all Android devices, but slightly slower on modern ones.
*   **`app-arm64-v8a-release.apk` (64-bit)**: 
    *   **Best for**: Modern phones (Android 8.0 and above). 
    *   **Compatibility**: Much faster and optimized for 64-bit processors found in the last 5-6 years.
*   **`app-x86_64-release.apk`**: 
    *   **Best for**: Android Emulators on PCs.

---

## 🔄 Auto-Update Feature

The app now automatically checks for updates on launch. To use this:

1.  Create a file named `version.json` in your repository.
2.  Add the following content:
    ```json
    {
      "version": "1.0.1",
      "url": "https://github.com/your-username/your-repo/releases/latest",
      "changelog": "Performance improvements and bug fixes."
    }
    ```
3.  Update the `UPDATE_URL` constant in `lib/main.dart` to point to the **raw** version of this JSON file.

---

### Windows EXE
Inside the `python_server` directory:
```powershell
pip install pyinstaller
pyinstaller --onefile --windowed --name "RemoteTrackpad" server.py
```

---

*Created with ❤️ for digital artists and power users.*
