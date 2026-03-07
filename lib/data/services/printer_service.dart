import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/order_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/strings.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  BluetoothInfo? _connectedDevice;
  bool _isConnected = false;

  BluetoothInfo? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;

  /// Initialize Bluetooth Print
  Future<void> initialize() async {
    try {
      // Check connection status
      _isConnected = await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      throw Exception('Error initializing Bluetooth: $e');
    }
  }

  /// Check if Bluetooth is available
  Future<bool> isAvailable() async {
    try {
      // Check if Bluetooth permission is granted
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// Check if Bluetooth is on
  Future<bool> isOn() async {
    try {
      // Check if Bluetooth is enabled
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      return enabled;
    } catch (e) {
      // If check fails, try to get paired devices as fallback
      try {
        final devices = await PrintBluetoothThermal.pairedBluetooths;
        return devices.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
  }

  /// Get paired Bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      // First check if permission is granted
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!granted) {
        throw Exception('Bluetooth permission not granted');
      }

      // Check if Bluetooth is enabled
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        throw Exception('Bluetooth is not enabled');
      }

      // Get paired devices
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      throw Exception('Error getting paired devices: $e');
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connect(BluetoothInfo device) async {
    try {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      if (connected) {
        _connectedDevice = device;
        _isConnected = true;
        return true;
      }
      _isConnected = false;
      return false;
    } catch (e) {
      _isConnected = false;
      throw Exception('Error connecting to device: $e');
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
      _isConnected = false;
    } catch (e) {
      throw Exception('Error disconnecting: $e');
    }
  }

  /// Print receipt
  Future<void> printReceipt(OrderModel order) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Printer not connected. Please connect to a printer first.');
    }

    try {
      // Load printer profile
      final profile = await CapabilityProfile.load();
      
      // Create generator (80mm paper)
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(
        AppStrings.appName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Struk Pembayaran',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
      bytes += generator.feed(1);

      bytes += generator.hr();
      bytes += generator.feed(1);

      // Order Info
      bytes += generator.row([
        PosColumn(text: 'ID Pesanan:', width: 6),
        PosColumn(text: order.id, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.feed(1);

      bytes += generator.row([
        PosColumn(text: 'Tanggal:', width: 6),
        PosColumn(
          text: DateFormatter.formatDateTimeForReceipt(order.createdAt),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.feed(1);

      bytes += generator.row([
        PosColumn(text: 'Metode:', width: 6),
        PosColumn(
          text: order.paymentMethod.toUpperCase(),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.feed(1);

      bytes += generator.hr();
      bytes += generator.feed(1);

      // Items
      for (var item in order.items) {
        // Product name
        bytes += generator.text(
          item.product.name,
          styles: const PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);

        // Price, quantity, and total
        final quantity = 'x${item.quantity}';
        final itemPrice = CurrencyFormatter.format(item.finalPrice);
        final itemTotal = CurrencyFormatter.format(item.total);

        bytes += generator.row([
          PosColumn(text: '$itemPrice $quantity', width: 7),
          PosColumn(
            text: itemTotal,
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.feed(1);
      }

      bytes += generator.hr();
      bytes += generator.feed(1);

      // Subtotal
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(
          text: CurrencyFormatter.format(order.subtotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.feed(1);

      // Discount
      if (order.totalDiscount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Diskon:', width: 6),
          PosColumn(
            text: CurrencyFormatter.format(order.totalDiscount),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.feed(1);
      }

      // Total
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: CurrencyFormatter.format(order.total),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
          ),
        ),
      ]);
      bytes += generator.feed(1);

      bytes += generator.hr(ch: '=');
      bytes += generator.feed(1);

      // Thank you message
      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Selamat Berbelanja Kembali',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.feed(2);

      // Cut paper
      bytes += generator.cut();

      // Print receipt
      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (!success) {
        throw Exception('Failed to print receipt');
      }
    } catch (e) {
      throw Exception('Error printing receipt: $e');
    }
  }

  /// Print test page
  Future<void> printTest() async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('Printer not connected. Please connect to a printer first.');
    }

    try {
      // Load printer profile
      final profile = await CapabilityProfile.load();
      
      // Create generator
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text(
        'TEST PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Printer Connected',
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.feed(2);

      bytes += generator.cut();

      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (!success) {
        throw Exception('Failed to print test');
      }
    } catch (e) {
      throw Exception('Error printing test: $e');
    }
  }
}
