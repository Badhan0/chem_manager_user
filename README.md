# Clini Sync - Elite Patient Care Portal 🏥✨

Welcome to **Clini Sync**, the premium, futuristic user companion app for the Chem Manager ecosystem. Designed for the "next-label" healthcare experience, Clini Sync provides patients with a world-class interface to manage their medical journey.

---

## 💎 Design Ethos
Clini Sync isn't just an app; it's a statement. Built with a **Futuristic Glassmorphic** UI, it features:
- **HSL-Curated Depth**: Deep Indigo and Cyber Cyan accents.
- **Micro-Animations**: Smooth transitions and interactive vitals.
- **Elite Typography**: Powered by the Google 'Outfit' font family.
- **Tacitile UI**: Neumorphic elements and 3D-styled service cards.

---

## 🚀 Key Features
- **Elite Booking**: One-tap access to find and book appointments with top clinicians.
- **Google One-Tap Auth**: Fast, secure login with automatic profile synchronisation.
- **Health Wallet**: Dedicated space for medical finances and digital records.
- **Live Vitals Monitor**: Interactive tracking for Heart Rate (BPM) and SpO2.
- **Digital Prescriptions**: Instant access to clinician-verified medication plans.

---

## 🛠️ Technical Stack
- **Frontend**: Flutter (3.x)
- **Backend**: Node.js/Express (Unified Chem Manager Backend)
- **Database**: MongoDB (Dedicated `patient_users` collection)
- **Security**: Firebase Auth + JWT
- **Design System**: Custom HSL tokens in `lib/theme/design_system.dart`

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- Flutter SDK installed.
- Access to the Chem Manager Backend (ensure it's running).

### 2. Backend Environment
The app connects to the unified backend. Ensure the backend has the `PatientUser` model and routes active.
- Default Base URL: `http://10.0.2.2:5000/api` (Android Emulator)

### 3. Firebase Configuration
To enable Google Sign-In and the futuristic authentication flow:
1. Create a Firebase project for "Clini Sync User".
2. Add an Android app and download `google-services.json`.
3. Place `google-services.json` in `android/app/`.

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run the App
```bash
flutter run
```

---

## 🛡️ Security Restrictions
**Professional Access Denied**: This application is strictly for Patient use. Doctors and Organization accounts registered in the primary Chem Manager system are automatically restricted from signing in here to ensure a dedicated patient-centric environment.

---

*Powered by the Chem Manager ecosystem. Designed for the Future.*
