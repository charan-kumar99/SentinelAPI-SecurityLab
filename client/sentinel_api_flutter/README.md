# 🛡️ SentinelAPI — Flutter Defensive Operations Client

A cross-platform **Flutter (Dart)** Security Operations Workbench designed to interface with the **SentinelAPI .NET 10 Cyber Security API**.

---

## 🔒 Security Operations Features

- 🔑 **Auth & JWT Workbench**: User Registration, Argon2id Password Hashing, JWT Bearer Token Inspection & Claims Parser.
- 🔐 **AES-256-GCM Field Encryption**: Real-time encryption of sensitive PII (SSN, Financial Data) stored into PostgreSQL.
- ⚔️ **Attack Sandbox**: Live execution & testing of SQL Injection exploits and XSS vector sanitization.
- ⚡ **Rate Limiter Hammer**: Burst traffic attack simulator with HTTP 429 Too Many Requests status indicators.
- 📊 **Security Audit Telemetry**: Real-time event stream monitoring Client IPs, endpoints, and threat risk levels.

---

## 🚀 Running the Flutter App

### Run on Chrome
```powershell
flutter run -d chrome
```

### Run on Windows Desktop
```powershell
flutter run -d windows
```

### Build Web Bundle
```powershell
flutter build web
```

---

## 🛠️ Technology Stack
- **Framework**: Flutter 3.x / Dart 3.x
- **UI Design**: Material 3 Dark Cyber Theme, Google Fonts (`Outfit` & `Fira Code`)
- **Networking**: `http` REST API Client connecting to SentinelAPI Backend at `http://localhost:5265`
