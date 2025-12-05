# 🚀 WorkHive – Real-Time Employee Tracking System

A modern **Flutter-based real-time worker tracking system** designed for startups & companies to monitor field employees, geofence compliance & live location updates.

![WorkHive Banner](https://user-images.githubusercontent.com/placeholder/banner.jpg)

---

## ✨ Features

### 🛰️ Real-Time Location Tracking  
- Employees send live GPS updates every **10 seconds**  
- Admin gets a **live dashboard** with worker locations  
- Map auto-refresh every 3 seconds  

### 🧭 Geofencing (500m Radius)  
- Shows if the worker is **INSIDE / OUTSIDE** company range  
- Visual geofence circle on map  

### 👨‍💼 Admin Panel  
- Approve / Reject new employee registrations  
- Monitor every worker’s:  
  - Status → `Tracking / Held / Stopped`  
  - Live Latitude / Longitude  
  - Geofence status  

### 👤 Employee App  
- Start / Hold / Stop tracking  
- See live location  
- Logout safety (Stops tracking automatically)  

### 🔐 Security  
- Admin login protected with:  
  - Admin Email  
  - Admin Password  
  - Private Key *(aurasecret)*  
- Simulated blockchain integrity check  

---

## 📡 Tech Stack

| Layer | Technology |
|------|-------------|
| UI | Flutter (Material 3) |
| Maps | Flutter Map + OpenStreetMap |
| Geofence | Haversine Formula |
| Live Tracking | Dart Timers (10s interval) |
| State Mgmt | ChangeNotifier |
| Backend | Simulated Manager Class |

---

## 🗺️ Screenshots

> Add your own screenshots here  
> (Just upload images in issues → copy link → paste here)

```
![Login](screenshot_link)
![Admin Panel](screenshot_link)
![Map View](screenshot_link)
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── admin_map_view.dart
├── admin_home_page.dart
├── employee_home_page.dart
├── worker_manager.dart
└── models/
    └── worker.dart
```

---

## 🧪 Live Worker Tracking Logic

### Worker sends updated location every **10 seconds**:
```dart
Timer.periodic(Duration(seconds: 10), (timer) {
  _simulateLocationUpdate(worker);
})
```

### Geofence check:
```dart
distanceKm = R * c;
worker.isInsideGeofence = distanceKm <= 0.5;
```

---

## 🗺️ Real-Time Map View

Features:  
✔️ Worker markers  
✔️ Color-coded status  
✔️ Click-to-view details  
✔️ 500m Geofence Circle  
✔️ Auto refresh  

---

## 🛠️ Setup Instructions

### 1. Clone the repo
```
git clone https://github.com/Ashu2060/workhive.git
```

### 2. Install packages
```
flutter pub get
```

### 3. Run app
```
flutter run
```

---

## 👨‍💻 Admin Credentials (Simulated)

| Field | Value |
|-------|--------|
| Name | Ashutosh |
| Email | ashu@gmail.com |
| Password | 805030 |
| Private Key | aurasecret |

---

## 📬 Contributing

Feel free to improve UI, backend, features.  
Pull requests are always welcome!  

---

## ⭐ Support

If you like this project, give it a **🌟 STAR** on GitHub — it motivates creators!

---

## 🧑‍💻 Author

**Ashutosh Kumar Jha**  
Flutter Developer | Mobile Apps | UI/UX  
