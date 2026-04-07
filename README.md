# 🚴 Smart Bike Rental — Setup & Run Guide

## 🌟 Features

*   **Customer App**: Browser bikes, select rental times, time-based availability checking, and auto-confirmed bookings.
*   **Vendor Portal**: Vendors can register, login, add their bikes, and manage bookings (Start Ride, Mark Completed, Cancel).
*   **KYC Verification**: Mandatory Driving License upload via Cloudinary before securing a booking.
*   **Simulated Payment Flow**: Supports UPI, Credit/Debit Card, Wallet, and Cash on Delivery (COD).
*   **Smart Availability**: Robust, time-based SQL overlap validation prevents double bookings.

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | v18+ |
| npm | v9+ |
| PostgreSQL | v14+ |
| Flutter SDK | v3.10+ |
| Dart SDK | v3.0+ |
| Android Studio / Emulator | Any recent |

---

## 1. PostgreSQL Database Setup

```bash
# Open PostgreSQL shell
psql -U postgres

# Create the database
CREATE DATABASE bike_rental_db;

# Exit shell
\q

# Run the schema to create all tables
psql -U postgres -d bike_rental_db -f backend/config/schema.sql
```

> **Note**: The backend runs auto-migrations on startup (`config/db.js`) to apply column updates automatically (like KYC flags).
> **Seed sample data** (optional — paste in psql):
> ```sql
> INSERT INTO vendors (name, phone, address, email, password) 
> VALUES ('BikePro Rentals', '9876543210', 'Pune, MH', 'vendor@test.com', '$2b$10$someHashedPassword');
>
> INSERT INTO bikes (vendor_id, model, price_per_hour, price_per_day, location, availability, engine_cc, bike_type)
> VALUES
>   (1, 'Activa 6G',  80,  500,  'Pune',   TRUE, 110, 'scooter'),
>   (1, 'Royal Enfield Classic 350', 200, 1200, 'Mumbai', TRUE, 350, 'cruiser');
> ```

---

## 2. Backend Setup

```bash
# Navigate to backend folder
cd backend

# Install all dependencies
npm install

# Copy the environment template and fill in your values
copy .env.example .env
```

### Edit `backend/.env`:

```env
PORT=5000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=bike_rental_db
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD

JWT_SECRET=replace_with_a_long_random_string
JWT_EXPIRES_IN=7d

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### Start the backend server:

```bash
# Production
npm start

# Development (auto-restarts on file changes)
npm run dev
```

Backend will be available at: **http://localhost:5000**

---

## 3. Cloudinary Configuration

1. Sign up at [cloudinary.com](https://cloudinary.com) (free tier available)
2. Go to **Dashboard** → copy:
   - Cloud Name
   - API Key
   - API Secret
3. Paste these into your `backend/.env`

License images uploaded via KYC `POST /api/upload-license` will be stored in the `bike_rental/licenses/` folder in your Cloudinary account.

---

## 4. Flutter App Setup

```bash
# Navigate to frontend folder
cd frontend

# Get all Flutter packages
flutter pub get

# For Android emulator — verify devices
flutter devices
```

### Configure API URL

Open `lib/services/api_service.dart` and `lib/vendor/vendor_api_service.dart` and update `baseUrl`:

```dart
// Android emulator (maps to your PC's localhost)
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Physical Android device (use your PC's local IP)
// static const String baseUrl = 'http://192.168.x.x:5000/api';

// iOS simulator
// static const String baseUrl = 'http://127.0.0.1:5000/api';
```

### Run the Flutter app:

```bash
flutter run
```

---

## 5. API Reference (Quick Test with curl/Postman)

### Auth & User
- `POST /api/auth/register` : User Registration
- `POST /api/auth/login` : User Login
- `GET /api/user/profile` : Get User KYC Status

### Bikes & Bookings
- `GET /api/bikes?start_time=ISO&end_time=ISO` : Get strictly available bikes (time-filtered overlap check)
- `POST /api/bookings` : Create a Booking (auto-confirms)
- `GET /api/bookings/user/1` : User's Booking History
- `POST /api/upload-license` : Upload KYC Driving License Image

### Vendor
- `POST /api/vendor/register` : Vendor Registration
- `POST /api/vendor/login` : Vendor Login
- `GET /api/vendor/bikes` : Vendor's Fleet
- `GET /api/vendor/bookings` : View all bookings for Vendor's bikes
- `PATCH /api/vendor/bookings/:id/status` : Update booking status (active, completed, cancelled)

---

## 6. Project Structure Overview

```
Prototype/
├── backend/                  ← Node.js Express API
│   ├── config/               ← DB setup & migrations
│   ├── controllers/          ← user, bike, booking, vendor logic
│   ├── middleware/           ← JWT auth check
│   ├── models/               ← Database SQL query functions
│   ├── routes/               ← Express routers
│   ├── uploads/              ← Temp image uploads
│   └── server.js             ← App entry point
│
└── frontend/                 ← Flutter mobile app
    └── lib/
        ├── main.dart         ← App entry + routing
        ├── screens/          ← User UI (Auth, KYC, Booking, Payment, History)
        ├── vendor/           ← Vendor UI (Auth, Dashboard, Fleet Mgmt, Bookings)
        └── services/         ← API Service Integrations
```
