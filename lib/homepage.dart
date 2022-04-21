import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Iniciar el bluetooth
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  late BluetoothConnection connection;
  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  late BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;
  bool isDisconnecting = false;
   /* Variables de los botones */
  bool lamparaState = false;
  bool aux1State = false;
  bool aux2State = false;
  bool sillaState = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }
// For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }
    setState(() {
      _devicesList = devices;
    });
  }
// Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      print('No device selected');
    } else {
      print(_device.isConnected);
      if (!_device.isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input?.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
              setState(() {
                _connected = false;
              });
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  void _onDataReceived(Uint8List data) async{
  //   // Allocate buffer for parsed data

   int backspacesCounter = 0;
     data.forEach((byte) {
       if (byte == 8 || byte == 127) {
        backspacesCounter++;
       }
     });
   Uint8List buffer = Uint8List(data.length - backspacesCounter);
     int bufferIndex = buffer.length;

  // Apply backspace control character
    backspacesCounter = 0;
     for (int i = data.length - 1; i >= 0; i--) {
     if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
         if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
     }
    }
    print(buffer);
   } 
  void _sendMessage(String message) async {
    connection.output.add(ascii.encode(message));
    await connection.output.allSent;
  }


  @override
  Widget build(BuildContext context) {
      /* Variables de la pantalla */
    double sh = MediaQuery.of(context).size.height;
    double sw = MediaQuery.of(context).size.width;
    
FloatingActionButton lampara = FloatingActionButton(
      child: const Icon(Icons.light),
      backgroundColor: lamparaState ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          lamparaState = !lamparaState;
          _sendMessage('A');
        });
      },
    );
    FloatingActionButton Aux1 = FloatingActionButton(
      child: const Icon(Icons.electrical_services),
      backgroundColor: aux1State ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          aux1State = !aux1State;
          _sendMessage('C');
        });
      },
    );
    FloatingActionButton Aux2 = FloatingActionButton(
      child: const Icon(Icons.electrical_services),
      backgroundColor: aux2State ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          aux2State = !aux2State;
          _sendMessage('E');
        });
      },
    );
    FloatingActionButton Silla = FloatingActionButton(
      child: const Icon(Icons.chair_alt_outlined),
      backgroundColor: sillaState ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          sillaState = !sillaState;

        });
      },
    );
    Row Navigate = Row(
      children: [
        const Spacer(flex: 2),
        lampara,
        const Spacer(),
        Aux1,
        const Spacer(),
        Aux2,
        const Spacer(),
        Silla,
        const Spacer(flex: 2),
      ],
    );

    FloatingActionButton sillaArriba = FloatingActionButton(
      child: const Icon(Icons.arrow_upward),
      backgroundColor: Colors.amber,
      onPressed: () {},
    );
    FloatingActionButton sillaAbajo = FloatingActionButton(
      child: const Icon(Icons.arrow_downward),
      backgroundColor: Colors.amber,
      onPressed: () {},
    );

    Padding botonesSilla = Padding(
      padding: EdgeInsets.only(left: sw - 60),
      child: Column(
        children: [
          const Spacer(flex: 10),
          sillaArriba,
          const Spacer(),
          sillaAbajo,
          const Spacer(flex: 10),
        ],
      ),
    );
  
    return SafeArea(
      child: Scaffold(
          body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              Colors.white,
              _bluetoothState == BluetoothState.STATE_ON
                  ? Colors.green
                  : Colors.red
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
         !_connected ?  Column(
            children: [
              Container(
                  child: Row(
                children: [
                  const Text('Buscar dispositivos Bluetooth'),
                  FloatingActionButton(
                    child: const Icon(Icons.bluetooth),
                    onPressed: () {
                      _bluetooth.openSettings();
                    },
                  )
                ],
              )),
              Row(
                children: [
                  const Text('Dispositivos vinculados'),
                  FloatingActionButton(
                      child: const Icon(Icons.refresh),
                      onPressed: () {
                        getPairedDevices();
                      }),
                ],
              ),
              SizedBox(
                  height: MediaQuery.of(context).size.height / 2,
                  child: _devicesList.isNotEmpty
                      ? ListView.builder(
                          itemCount: _devicesList.length,
                          itemBuilder: (context, index) {
                            return Row(
                              children: [
                                Text(_devicesList[index].name.toString()),
                                FloatingActionButton(onPressed: () {
                                  _device = _devicesList[index];
                                  _connect();
                                })
                              ],
                            );
                          },
                        )
                      : const Text("No hay dispositivos emparejados")),

            ],
          ): 
          Navigate
        ],
      )),
    );
  }
}
