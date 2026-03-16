import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/services/printer_service.dart';

class PrinterScanPage extends StatefulWidget {
  final Function(BluetoothInfo)? onPrinterSelected;

  const PrinterScanPage({
    super.key,
    this.onPrinterSelected,
  });

  @override
  State<PrinterScanPage> createState() => _PrinterScanPageState();
}

class _PrinterScanPageState extends State<PrinterScanPage> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothInfo> _devices = [];

  bool _isLoading = false;
  bool _isConnecting = false;

  BluetoothInfo? _selectedDevice;

  String? _errorMessage;

  bool _isBluetoothAvailable = false;
  bool _isBluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _printerService.initialize();

      final isAvailable = await _printerService.isAvailable();
      final isEnabled = await _printerService.isOn();

      setState(() {
        _isBluetoothAvailable = isAvailable;
        _isBluetoothEnabled = isEnabled;
      });

      if (!isAvailable) {
        setState(() {
          _errorMessage =
              'Bluetooth permission not granted. Please grant Bluetooth permission.';
          _isLoading = false;
        });
        return;
      }

      if (!isEnabled) {
        setState(() {
          _errorMessage =
              'Bluetooth is not enabled. Please enable Bluetooth.';
          _isLoading = false;
        });
        return;
      }

      await _loadPairedDevices();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing Bluetooth: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devices = await _printerService.getPairedDevices();

      setState(() {
        _devices = devices;
        _isLoading = false;
      });

      if (devices.isEmpty) {
        setState(() {
          _errorMessage =
              'No Bluetooth printers found.\nPair your printer in Bluetooth settings then press Refresh.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading devices: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothInfo device) async {
    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
      _errorMessage = null;
    });

    try {
      final connected = await _printerService.connect(device);

      if (connected) {
        if (widget.onPrinterSelected != null) {
          widget.onPrinterSelected!(device);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.name}'),
              backgroundColor: AppColors.success,
            ),
          );

          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to printer.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _printerService.disconnect();

      setState(() {
        _selectedDevice = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer disconnected'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: $e'),
          ),
        );
      }
    }
  }

  Widget bluetoothWarning(String text) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = _printerService.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bluetooth Printer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text("How to Connect"),
                  content: Text(
                    "1. Turn on Bluetooth\n"
                    "2. Pair printer in phone settings\n"
                    "3. Return to the app\n"
                    "4. Tap refresh\n"
                    "5. Select the printer",
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPairedDevices,
          ),
        ],
      ),
      body: Column(
        children: [

          if (!_isBluetoothAvailable)
            bluetoothWarning("Bluetooth permission not granted"),

          if (_isBluetoothAvailable && !_isBluetoothEnabled)
            bluetoothWarning("Bluetooth is turned off"),

          if (connectedDevice != null && _printerService.isConnected)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.print, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Connected Printer",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(connectedDevice.name),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _disconnect,
                  )
                ],
              ),
            ),

          Expanded(
            child: !_isBluetoothAvailable || !_isBluetoothEnabled
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: _initializeBluetooth,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                    ),
                  )
                : _isLoading
                    ? const LoadingWidget()
                    : _devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.print_disabled,
                                  size: 70,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No printers found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Pair printer in Bluetooth settings",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _loadPairedDevices,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Refresh"),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];

                              final isConnected =
                                  connectedDevice?.macAdress ==
                                      device.macAdress;

                              final isConnecting =
                                  _isConnecting &&
                                      _selectedDevice?.macAdress ==
                                          device.macAdress;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6,
                                      color: Colors.black.withOpacity(0.05),
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isConnected
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    child: Icon(
                                      Icons.print,
                                      color: isConnected
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    device.name,
                                    style: TextStyle(
                                      fontWeight: isConnected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    device.macAdress,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: isConnected
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : isConnecting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            )
                                          : ElevatedButton(
                                              onPressed: () =>
                                                  _connectToDevice(device),
                                              child:
                                                  const Text("Connect"),
                                            ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}