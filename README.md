# Point of Sale App

A Flutter-based Point of Sale (POS) application with offline support, BLoC state management, and Bluetooth thermal printer integration.

## Features

- **Authentication**: Login with admin and user roles
- **Admin Features**:
  - CRUD operations for products (Food & Drink categories)
  - Product management (name, price, stock, discount, image, description)
  - Financial reports with charts (daily, weekly, monthly, yearly)
  - PDF export for financial reports
- **User Features**:
  - Browse products with categories
  - Add products to cart
  - Payment options (Cash/QR Code)
  - Receipt printing (PDF and Bluetooth thermal printer)

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Android Studio / Xcode
- Android device with Bluetooth (for thermal printer)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Bluetooth Printer Setup

The app supports Bluetooth thermal printer for receipt printing using `print_bluetooth_thermal` package. Before using:
1. Pair your Bluetooth thermal printer with your Android device (via device Bluetooth settings)
2. Open the app and go to Receipt page
3. Tap "Pilih Printer" to see paired printers and connect to your printer
4. Once connected, you can print receipts directly from the app

**Note**: Make sure Bluetooth permissions are granted for the app to work properly.

## Project Structure

```
lib/
├── core/           # Core utilities, constants, widgets
├── data/           # Models, services, storage
└── presentation/   # BLoC, views (admin & user)
```

## Build for Android

```bash
flutter build apk --debug
```

For release:
```bash
flutter build apk --release
```

## Troubleshooting

### Build Errors
If you encounter build errors:
1. Clean and rebuild: `flutter clean && flutter pub get`
2. Make sure all dependencies are up to date

### Bluetooth Printer Issues
1. Make sure Bluetooth is enabled on your device
2. Pair your printer with the device first (via device Bluetooth settings)
3. Grant Bluetooth permissions to the app
4. If printer is not found, make sure it's paired and in range

## License

This project is private and not for distribution.
