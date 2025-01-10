import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino LED Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  bool isConnecting = false;
  bool isConnected = false;
  bool ledState = false;

  final TextEditingController _countController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    try {
      bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isEnabled) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {});
    } catch (e) {
      print('Error scanning devices: $e');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');

      setState(() {
        isConnecting = false;
        isConnected = true;
      });

      connection!.input!.listen((Uint8List data) {
        String response = ascii.decode(data);
        print('Received: $response');
      }).onDone(() {
        setState(() {
          isConnected = false;
        });
      });
    } catch (e) {
      print('Error connecting: $e');
      setState(() {
        isConnecting = false;
      });
    }
  }

  void _sendCommand(String command) {
    if (connection?.isConnected ?? false) {
      connection!.output.add(Uint8List.fromList(utf8.encode(command + "\n")));
    }
  }

  void _toggleLED() {
    if (!ledState) {
      _sendCommand("ON");
    } else {
      _sendCommand("OFF");
    }
    setState(() {
      ledState = !ledState;
    });
  }

  void _blinkLED() {
    if (_countController.text.isNotEmpty && _delayController.text.isNotEmpty) {
      String command = "BLINK ${_countController.text},${_delayController.text}";
      _sendCommand(command);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino LED Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanDevices,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected) ...[
              const Text(
                'Paired Devices:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      child: ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        trailing: ElevatedButton(
                          onPressed: isConnecting ? null : () => _connect(device),
                          child: Text(isConnecting ? 'Connecting...' : 'Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 48,
                        color: ledState ? Colors.yellow : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _toggleLED,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ledState ? Colors.red : Colors.green,
                        ),
                        child: Text(
                          ledState ? 'Turn OFF' : 'Turn ON',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Blink Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _countController,
                        decoration: const InputDecoration(
                          labelText: 'Blink Count',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _delayController,
                        decoration: const InputDecoration(
                          labelText: 'Delay (ms)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _blinkLED,
                        child: const Text('Start Blinking'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    connection?.dispose();
    _countController.dispose();
    _delayController.dispose();
    super.dispose();
  }
}