# RideWalaa 🚗💨

RideWalaa is a premium, real-time ride-hailing application designed for modern passengers and drivers. Built using **Flutter** and synchronized in real-time via **Firebase**, the app delivers a seamless and dynamic taxi-booking experience.

---

## Key Features

### Advanced Authentication & Onboarding
*   **Google OAuth Sign-In**: Single-click "Continue with Google" sign-in for seamless onboarding.
*   **Auto-Registration**: Automatic profile creation in Cloud Firestore for new sign-ups.
*   **Role Validation**: Strict role validation separating Passengers and Drivers during login.
*   **Custom Verification Dialogs**: Premium, clean pop-up error dialogs translating technical Firebase exceptions into user-friendly alerts.

### Live-Synced Ride Experience
*   **Animated Map Simulation**: Interactive map displaying animated passenger markers (Pin) and driver markers (Car) sliding dynamically across the screen using `AnimatedPositioned` at 60fps.
*   **Pulsing Search Radar**: Custom repeating ripple circular animations during the search phase.
*   **Firestore Synchronization**: Instant real-time database listener syncing state progression (`searching` ➔ `accepted` ➔ `arrived` ➔ `picked_up` ➔ `completed` ➔ `cancelled`).

### Passenger & Driver Modules
*   **Passenger Panel**: Select vehicle types (Bike, Economy, Premium), adjust distances with a slider, estimate fare amounts, and monitor driver progress dynamically.
*   **Driver Dashboard**: Set online/offline status, receive incoming booking requests, and manage trip milestones (Arrive, Start, Complete, Cancel) with direct updates to the passenger.

---

## Technology Stack
*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Authentication, Cloud Firestore)
*   **OAuth**: Google Sign-In (`google_sign_in`)
*   **Styling**: Google Fonts (Roboto & Material Icons)

---

## Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
*   Firebase Project configuration (`firebase_options.dart`, `google-services.json`)

### Installation & Run

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/Riderr_app.git
    cd Riderr_app
    ```

2.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    *   To run on **Web (Chrome)**:
        ```bash
        flutter run -d chrome
        ```
    *   To run on **Android/iOS Mobile**:
        ```bash
        flutter run
        ```

---

## Security & Git Best Practices
Sensitive credentials and configuration keys (such as `google-services.json` and `firebase_options.dart`) are explicitly ignored inside the `.gitignore` configuration to prevent accidental exposure on GitHub.
