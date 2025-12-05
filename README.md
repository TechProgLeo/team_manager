# 🏆 Team Manager App

**Team Manager** is a Flutter application designed to help sports teams or training groups easily manage and organize their training sessions. The app makes it simple to view upcoming trainings, track attendance, and plan recurring sessions. The backend is built using **Firebase Authentication** and **Firestore**.

---

## 🚀 Features

- 🔐 **Secure Sign-In & Sign-Up** using Firebase Authentication  
- 📅 **View Upcoming Trainings** on the home screen  
- ➕ **Create Trainings** with custom date, time, and location  
- 🔁 **Schedule Recurring Trainings** (daily or weekly)  
- ❌ **Delete Individual or Series of Trainings**  
- ✅ **Track Attendance** *(optional future enhancement)*  
- 🧾 **Clean and organized UI** with intuitive interactions  

---

## 🛠️ Tech Stack

- **Frontend:** Flutter & Dart  
- **Backend:** Firebase Authentication & Cloud Firestore  
- **State Management:** SetState *(can scale to Provider, Riverpod, etc.)*  

---

## 📂 Folder Structure

lib/
├── main.dart
├── pages/
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── trainings_page.dart
│   └── training_detail_page.dart
└── widgets/