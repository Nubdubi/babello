import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrSocketPage extends StatefulWidget {
  const QrSocketPage({super.key});

  @override
  State<QrSocketPage> createState() => _QrSocketPageState();
}

class _QrSocketPageState extends State<QrSocketPage> {
  IO.Socket? socket;
  bool connected = false;
  String? scannedUrl;
  String? mySocketId;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _connectToServer(String url) {
    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      setState(() {
        connected = true;
        mySocketId = socket!.id;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ 연결 성공: $url')));
    });

    socket!.on('message', (data) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('📩 받은 메시지: $data')));
    });

    socket!.connect();
  }

  void _sendMessage() {
    if (socket != null && connected) {
      socket!.emit('message', _controller.text);
      _controller.clear();
    }
  }

  void _disconnect() {
    socket?.disconnect();
    setState(() => connected = false);
  }

  void _showQrDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR 코드 공유'),
        content: QrImageView(data: url, version: QrVersions.auto, size: 200.0),
      ),
    );
  }

  void _scanQrCode() {
    showDialog(
      context: context,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('QR 코드 스캔')),
          body: MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null) {
                Navigator.pop(context);
                setState(() => scannedUrl = code);
                _connectToServer(code);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sampleServerUrl = "https://your-socket-server.com";

    return Scaffold(
      appBar: AppBar(title: const Text('🔗 QR Socket 통신 페이지')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!connected)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showQrDialog(sampleServerUrl),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR 코드로 내 주소 공유'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _scanQrCode,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('QR 코드 스캔하여 연결'),
                  ),
                ],
              ),
            if (connected)
              Expanded(
                child: Column(
                  children: [
                    Text('🟢 연결됨: $mySocketId'),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: '메시지 입력...'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                    ElevatedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.close),
                      label: const Text('연결 종료'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
