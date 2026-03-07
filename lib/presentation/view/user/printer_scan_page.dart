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
      
      // Check permissions
      final isAvailable = await _printerService.isAvailable();
      
      // Check if Bluetooth is enabled
      final isEnabled = await _printerService.isOn();
      
      setState(() {
        _isBluetoothAvailable = isAvailable;
        _isBluetoothEnabled = isEnabled;
      });

      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Izin Bluetooth tidak diberikan. Silakan berikan izin Bluetooth di pengaturan aplikasi.';
          _isLoading = false;
        });
        return;
      }

      if (!isEnabled) {
        setState(() {
          _errorMessage = 'Bluetooth tidak aktif. Silakan aktifkan Bluetooth di pengaturan perangkat.';
          _isLoading = false;
        });
        return;
      }

      // Load paired devices
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
          _errorMessage = 'Tidak ada printer Bluetooth yang ditemukan.\n\nCara mengatasi:\n1. Buka Pengaturan Bluetooth di perangkat Anda\n2. Pastikan Bluetooth aktif\n3. Pindai dan pasangkan printer Anda\n4. Kembali ke aplikasi dan tekan Refresh';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading devices: $e';
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
              content: Text('Berhasil terhubung ke ${device.name}'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal terhubung ke printer. Pastikan printer dalam jangkauan dan sudah dipasangkan.';
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
            content: Text('Printer terputus'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = _printerService.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Printer Bluetooth'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cara Menggunakan'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aplikasi ini hanya menampilkan printer yang sudah dipasangkan (paired) di pengaturan Bluetooth perangkat Anda.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text('Langkah-langkah:'),
                        SizedBox(height: 8),
                        Text('1. Buka Pengaturan Bluetooth di perangkat Anda'),
                        SizedBox(height: 4),
                        Text('2. Pastikan Bluetooth aktif'),
                        SizedBox(height: 4),
                        Text('3. Pindai dan pasangkan printer thermal Anda'),
                        SizedBox(height: 4),
                        Text('4. Kembali ke aplikasi dan tekan tombol Refresh'),
                        SizedBox(height: 4),
                        Text('5. Pilih printer dari daftar yang muncul'),
                        SizedBox(height: 16),
                        Text(
                          'Catatan: Printer harus sudah dipasangkan terlebih dahulu di pengaturan perangkat sebelum muncul di aplikasi.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Bantuan',
          ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPairedDevices,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          // Bluetooth Status
          if (!_isBluetoothAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Text(
                      'Izin Bluetooth tidak diberikan. Silakan berikan izin Bluetooth di pengaturan aplikasi.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bluetooth Not Enabled
          if (_isBluetoothAvailable && !_isBluetoothEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Text(
                      'Bluetooth tidak aktif. Silakan aktifkan Bluetooth di pengaturan perangkat.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Connection Status
          if (connectedDevice != null && _printerService.isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              color: AppColors.success.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth_connected,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terhubung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          connectedDevice.name,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _disconnect,
                    tooltip: 'Disconnect',
                  ),
                ],
              ),
            ),

          // Error Message (only show if not in empty state)
          if (_errorMessage != null && _devices.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Device List
          Expanded(
            child: !_isBluetoothAvailable || !_isBluetoothEnabled
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          !_isBluetoothAvailable
                              ? 'Izin Bluetooth tidak diberikan'
                              : 'Bluetooth tidak aktif',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppSizes.fontSizeM,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        CustomButton(
                          text: 'Coba Lagi',
                          onPressed: _initializeBluetooth,
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  )
                : _isLoading
                    ? const LoadingWidget()
                    : _devices.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSizes.paddingL),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_searching,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSizes.paddingM),
                                  Text(
                                    'Tidak ada printer ditemukan',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontSizeL,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSizes.paddingM),
                                  if (_errorMessage != null && _errorMessage!.contains('Cara mengatasi'))
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(AppSizes.paddingM),
                                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.info.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: AppColors.info,
                                                size: 20,
                                              ),
                                              const SizedBox(width: AppSizes.paddingS),
                                              Text(
                                                'Cara mengatasi:',
                                                style: TextStyle(
                                                  fontSize: AppSizes.fontSizeM,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.info,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSizes.paddingS),
                                          ..._errorMessage!
                                              .split('\n')
                                              .where((line) => line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line.trim()))
                                              .map((line) => Padding(
                                                    padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '• ',
                                                          style: TextStyle(
                                                            fontSize: AppSizes.fontSizeS,
                                                            color: AppColors.textPrimary,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                                                            style: TextStyle(
                                                              fontSize: AppSizes.fontSizeS,
                                                              color: AppColors.textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                        ],
                                      ),
                                    )
                                  else if (_errorMessage != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(AppSizes.paddingM),
                                      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontSize: AppSizes.fontSizeS,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: AppSizes.paddingL),
                                  CustomButton(
                                    text: 'Refresh',
                                    onPressed: _loadPairedDevices,
                                    icon: Icons.refresh,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final isConnected = connectedDevice?.macAdress == device.macAdress;
                              final isConnecting = _isConnecting && _selectedDevice?.macAdress == device.macAdress;

                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                                child: ListTile(
                                  leading: Icon(
                                    isConnected
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth,
                                    color: isConnected
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                  title: Text(
                                    device.name,
                                    style: TextStyle(
                                      fontWeight: isConnected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(device.macAdress),
                                  trailing: isConnected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.success,
                                        )
                                      : isConnecting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.link),
                                              onPressed: () => _connectToDevice(device),
                                              tooltip: 'Connect',
                                            ),
                                  onTap: isConnected || isConnecting
                                      ? null
                                      : () => _connectToDevice(device),
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
