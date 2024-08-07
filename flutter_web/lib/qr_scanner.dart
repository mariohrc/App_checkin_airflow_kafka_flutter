import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'float_button.dart';
import 'api_service.dart'; // Adjust the import according to your project structure

const bgColor = Color(0xfffafafa);

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
  bool isProcessing = false;
  bool isDialogOpen = false;

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

    if (state == AppLifecycleState.resumed) {
      startScanning();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      stopScanning();
    }
  }

  Future<void> startScanning() async {
    await controller.start();
    _subscription = controller.barcodes.listen(onQrCodeDetect);
  }

  Future<void> stopScanning() async {
    await controller.stop();
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> onQrCodeDetect(BarcodeCapture barcodeCapture) async {
    if (controller.value.isRunning && !isProcessing && !isDialogOpen) {
      isProcessing = true; // Set the flag to indicate processing is ongoing
      try {
        final Barcode barcode = barcodeCapture.barcodes.first;

        if (barcode.format == BarcodeFormat.qrCode) {
          await stopScanning();
          await processBarcode(barcode);
        }
      } catch (error) {
        print('Error during QR code processing: $error');
        await startScanning();
      } finally {
        isProcessing = false; // Reset the flag after processing
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
      await startScanning();
    }
  }

  void _showErrorDialog(String message) {
    isDialogOpen = true;
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
                isDialogOpen = false;
                Navigator.of(dialogContext).pop();
                startScanning();
              },
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog(String message, bool success) {
    isDialogOpen = true;
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
                isDialogOpen = false;
                Navigator.of(dialogContext).pop();
                startScanning();
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
    stopScanning();
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
      floatingActionButton: FloatingButtonWidget(onStop: stopScanning),
    );
  }
}
