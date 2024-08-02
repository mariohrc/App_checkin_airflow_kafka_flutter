import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'float_button.dart';

const bgColor = Color(0xfffafafa);

class ApiService {
  final String baseUrl;
  final Dio _dio;

  ApiService(this.baseUrl) : _dio = Dio();

  Future<bool> checkCodeExists(String qrcode, String readerName) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/check-code/',
        queryParameters: {
          'qrcode': qrcode,
          'reader_name': readerName,
        },
      );
      return response.statusCode == 201; // Check for 200 Created
    } catch (e) {
      print('Error checking code: $e');
      return false;
    }
  }
}

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with WidgetsBindingObserver {
  late MobileScannerController controller;
  StreamSubscription<Object?>? _subscription;
  final TextEditingController _readerNameController = TextEditingController();
  String? readerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      formats: [
        BarcodeFormat.qrCode,
      ],
      detectionSpeed: DetectionSpeed.normal,
      cameraResolution: const Size(1920, 1080),
    );
    startScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = controller.barcodes.listen(onQrCodeDetect);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  Future<void> startScanning() async {
    await Future.delayed(const Duration(seconds: 1));
    await controller.start();
    _subscription = controller.barcodes.listen(onQrCodeDetect);
  }

  Future<void> onQrCodeDetect(BarcodeCapture barcodeCapture) async {
    if (controller.value.isRunning) {
      try {
        final Barcode barcode = barcodeCapture.barcodes.first;

        if (barcode.format == BarcodeFormat.qrCode) {
          controller.stop();
          await processBarcode(barcode);
        }
      } catch (error) {
        print('Error during QR code processing: $error');
        controller.start();
      }
    }
  }

  Future<void> processBarcode(Barcode barcode) async {
    if (barcode.displayValue != null) {
      print('QR Code value: ${barcode.displayValue}');

      if (readerName == null || readerName!.isEmpty) {
        if (mounted) {
          _showErrorDialog('Reader name is required.');
        }
        return;
      }

      ApiService apiService = ApiService('http://192.168.3.198:80/');
      bool codeExists =
          await apiService.checkCodeExists(barcode.displayValue!, readerName!);

      if (mounted) {
        _showResultDialog(
          codeExists
              ? 'Code exists in the database and check-in/out recorded.'
              : 'Code does not exist in the database.',
          codeExists,
        );
      }
    } else {
      controller.start();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.start();
              },
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog(String message, bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            success ? 'Success' : 'Error',
            style: TextStyle(
              color: success ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.start();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    controller.stop();
    controller.dispose();
    _readerNameController.dispose();
    super.dispose();
  }

  void _setReaderName(String name) {
    setState(() {
      readerName = name;
    });
  }

  void _clearReaderName() {
    setState(() {
      readerName = null;
      _readerNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'QR Code Scanner',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Coloque o QR Code dentro da área',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
              const Text(
                'O Scan será feito automaticamente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              if (readerName == null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _readerNameController,
                        onSubmitted: _setReaderName,
                        decoration: const InputDecoration(
                          labelText: 'Enter Reader Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: 'setReaderName',
                      onPressed: () {
                        if (_readerNameController.text.isNotEmpty) {
                          _setReaderName(_readerNameController.text);
                        }
                      },
                      backgroundColor: const Color.fromARGB(255, 199, 23, 23),
                      child: const Icon(Icons.check),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reader Name: $readerName',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearReaderName,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black38),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Center(
                    child: MobileScanner(
                      controller: controller,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Desenvolvido por Mário =D',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const FloatingButtonWidget(),
    );
  }
}
