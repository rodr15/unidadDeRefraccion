import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConectionWithGadget extends StatefulWidget {
  const ConectionWithGadget({Key? key}) : super(key: key);

  @override
  State<ConectionWithGadget> createState() => _ConectionWithGadgetState();
}

class _ConectionWithGadgetState extends State<ConectionWithGadget> {
  // VARIABLES Y FUNCIONES PARA EL BLUETOOTH
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
  bool isConecting = false; // varialbe para la pantalla de carga
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
        _devicesList.clear();
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

// Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
    } else {
      await getPairedDevices();
    }
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
        setState(() {
          isConecting = true;
        });
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
            isConecting = false;
            _sendMessage("Z");
          });

          connection.input?.listen(_onDataReceived).onDone(() {
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
          setState(() {
            isConecting = false;
          });
          print('Cannot connect, exception occurred');
          print(error);
        });

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
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
    String decode = ascii.decode(buffer);
    print(decode);
    switch (decode) {
      case "A:1": // lampara encendida
        lamparaState = true;
        break;
      case "A:0": // lampara apagada
        lamparaState = false;
        break;
      case "C:1": // Aux1 encendida
        aux1State = true;
        break;
      case "C:0": // Aux1 apagada
        aux1State = false;
        break;
      case "E:1": // Aux2 encendida
        aux2State = true;
        break;
      case "E:0": // Aux2 apagada
        aux2State = false;
        break;
      
      default:
    }
    setState(() {});
  }

  void _sendMessage(String message) async {
    connection.output.add(ascii.encode(message));
    await connection.output.allSent;
  }

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;
    // PANTALLA DE CONEXION
    Container fondoConection = Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          _bluetoothState.isEnabled ? Colors.green : Colors.red,
          Colors.black
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      )),
    );
    Padding listaDispositivos = Padding(
      padding: EdgeInsets.only(left: sw * 1 / 20, top: sh * 2.5 / 10),
      child: Container(
          width: sw * 9 / 10,
          height: sh * 7.5 / 10,
          decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30), topLeft: Radius.circular(30))),
          child: _bluetoothState.isEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          "Dispositivos",
                          style: TextStyle(
                            fontSize: 50,
                            color: Colors.green,
                          ),
                        ),
                        FloatingActionButton(
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                getPairedDevices();
                              });
                            })
                      ],
                    ),
                    Expanded(
                      child: _devicesList.isNotEmpty
                          ? ListView.builder(
                              itemCount: _devicesList.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: sh * 0.1,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        _devicesList[index].name.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      FloatingActionButton(
                                          child: const Icon(
                                            Icons.phone,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            _device = _devicesList[index];
                                            _connect();
                                          }),
                                    ],
                                  ),
                                );
                              },
                            )
                          : const Text(
                              " No hay dispositivos disponibles",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 25),
                            ),
                    )
                  ],
                )
              : const Center(
                  child: Text(
                    "Bluetooth desactivado",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.red,
                    ),
                  ),
                )),
    );
    Padding encenderBluetooth = Padding(
      padding: EdgeInsets.only(left: sw * 0.1, top: sh * 0.068),
      child: Row(
        children: [
          const Text(
            "BLUETOOTH",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          FloatingActionButton(
              backgroundColor:
                  _bluetoothState.isEnabled ? Colors.green : Colors.red,
              child: Icon(
                _bluetoothState.isEnabled
                    ? Icons.bluetooth
                    : Icons.bluetooth_disabled,
                color: Colors.white,
              ),
              onPressed: () {
                enableBluetooth();
              }),
          Text(
            _bluetoothState.isEnabled ? "Encendido" : "Apagado",
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer()
        ],
      ),
    );
    Stack conectionScreen = Stack(
      children: [fondoConection, listaDispositivos, encenderBluetooth],
    );
    // PANTALLA DE CARGA
    Padding waitingIcon = Padding(
      padding: EdgeInsets.only(left: sw * 0.45, top: sh * 0.7),
      child: const CircularProgressIndicator(
        color: Colors.amber,
      ),
    );
    Padding textConection = Padding(
      padding: EdgeInsets.only(left: sw * 0.1, top: sh * 0.6),
      child: const Text(
        "Conectando con el dispositivo",
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
    Stack waitingConectionScreen = Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        textConection,
        waitingIcon
      ],
    );
    // PANTALLA DE FUNCIONAMIENTO
    Container fondoMovement = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.blue,
          Colors.black,
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
    );
    Padding iconsMovement = Padding(
        padding: EdgeInsets.only(left: sw * 0.025, top: sh * 0.85),
        child: Container(
            height: sh * 0.1,
            width: sw * 0.95,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.light,
                    color: lamparaState ? Colors.green : Colors.red,
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      lamparaState = !lamparaState;
                    });
                    _sendMessage("A");
                  },
                ),
                FloatingActionButton(
                    backgroundColor: Colors.black,
                    onPressed: () {
                      setState(() {
                        aux1State = !aux1State;
                      });
                      _sendMessage("C");
                    },
                    child: Icon(
                      Icons.electrical_services,
                      color: aux1State ? Colors.green : Colors.red,
                      size: 35,
                    )),
                FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: () {
                    setState(() {
                      aux2State = !aux2State;
                    });
                    _sendMessage("E");
                  },
                  child: Icon(
                    Icons.electrical_services,
                    color: aux2State ? Colors.green : Colors.red,
                    size: 35,
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: () {},
                  child: Icon(
                    Icons.chair,
                    color: sillaState ? Colors.green : Colors.red,
                    size: 35,
                  ),
                ),
              ],
            )));
    Padding animationMovement = Padding(
      padding: EdgeInsets.only(left: sw * 0.05, top: sh * 0.05),
      child: Container(
        width: sw * 0.9,
        height: sh * 0.75,
        color: Colors.blueGrey,
      ),
    );
    Stack movementScreen = Stack(
      children: [fondoMovement, iconsMovement, animationMovement],
    );

    return SafeArea(
        child: isConecting
            ? waitingConectionScreen
            : _connected
                ? movementScreen
                : conectionScreen);
  }
}
