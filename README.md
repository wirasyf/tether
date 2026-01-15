# Tether

**Tether** is a touch-based Long Distance Relationship (LDR) communication application designed to help partners feel connected across any distance. It goes beyond simple messaging by offering shared experiences, real-time touch visualization, and creative ways to express affection.

## ✨ Key Features

*   **❤️ Real-time Touch & Gestures**: Visualize and feel your partner's touch on the screen in real-time ("Ghost Touch").
*   **🎨 Shared Canvas**: Draw together on a shared synchronous canvas.
*   **💌 Love Notes**: Send intimate notes to your partner.
*   **📸 Photo Memory**: Share and keep your precious memories in a dedicated space.
*   **📅 Special Dates**: Track anniversaries and important milestones.
*   **🏆 Achievements**: Unlock milestones as your relationship grows.
*   **📱 Home Widget**: Keep your partner close right from your home screen.
*   **🔗 Seamless Pairing**: Easy partner connecting user experience.
*   **📊 Stats**: View insights into your connection.

## 🛠️ Tech Stack

This project is built with **Flutter** and relies on **Firebase** for backend services.

*   **Framework**: Flutter (SDK ^3.10.4)
*   **State Management**: Provider
*   **Backend**: Firebase (Auth, Database, Storage, Messaging)
*   **Real-time**: Firebase Database & Socket.IO
*   **Authentication**: Google Sign-In & Firebase Auth
*   **Animations**: Flutter Animate & Lottie
*   **Local Storage**: Shared Preferences
*   **Haptics**: Vibration package

## 🚀 Getting Started

Follow these steps to get a local copy of the project up and running.

### Prerequisites

*   **Flutter SDK**: Ensure you have Flutter installed. [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **Dart SDK**: Included with Flutter.
*   **Firebase Project**: You will need a Firebase project set up for this app.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/wirasyf/tether.git
    cd tether
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    *   This app relies on Firebase. You must have the generated `firebase_options.dart` or `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).
    *   Place `google-services.json` in `android/app/`.
    *   Place `GoogleService-Info.plist` in `ios/Runner/`.
    *   Ensure the package name in Firebase matches the one in your default config (e.g., `com.hummatech.tether` or similar).

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📂 Project Structure

 The code is organized into a clean architecture with distinct `core` and `features` directories:

*   **`lib/core`**: Contains shared services (Auth, Database, Settings), themes, and utilities used across the app.
*   **`lib/features`**: Contains self-contained feature modules (e.g., `canvas`, `love_notes`, `pairing`), each managing its own UI and logic.
*   **`lib/shared`**: (If applicable) specific shared UI components or models.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request