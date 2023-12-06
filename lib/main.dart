import 'dart:async';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'connect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',//僅能用name
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      ),
    defaultTransition: Transition.fade,
    getPages: AppPages.pages,
    home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("SPIE"),
        centerTitle: true,
      ),
      drawer: scaffold_draw_set(),
      body: GetBuilder<BLEController>(
        init: BLEController(),
        builder: (controller){
          return Column(
            children:[
              Expanded(
                child:SingleChildScrollView(
                  child: Column(
                    children: [
                      StreamBuilder<List<DiscoveredDevice>>(
                            stream: controller.dataStream,
                            builder: (context, snapshot){
                              if (snapshot.hasData){
                                return ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: snapshot.data!.length,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index){
                                      final data = snapshot.data![index];
                                      return Card(
                                        elevation: 3,
                                        child: InkWell(
                                          child: ListTile(
                                            title: data.name== "" ? const Text("No name") : Text(data.name),
                                            subtitle: Text(data.id),
                                            trailing: Text(data.rssi.toString()),
                                          ),
                                          onTap: (){
                                            print(data.id);
                                            Get.toNamed("/Connect_page", arguments: data.id);
                                            controller._streamSubscription?.cancel();
                                            controller.connect(data.id);
                                          },
                                        )
                                      );
                                    }
                                );
                              }
                              else{
                                return const Center(
                                  child: Text("NO FOUND DEVICE"),
                                );
                              }
                           },
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: ()=>controller.scan(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(350, 55),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                  ),
                  child: const Text(
                    "Start",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ) ,
    );
  }
}

class BLEController extends GetxController{
  final flutterReactiveBle = FlutterReactiveBle();
  StreamController<List<DiscoveredDevice>> _dataController = StreamController<List<DiscoveredDevice>>();
  Stream<List<DiscoveredDevice>> get dataStream => _dataController.stream;
  StreamSubscription<DiscoveredDevice>? _streamSubscription;
  List<DiscoveredDevice> _device_t=[];
  StreamSubscription<ConnectionStateUpdate>? _connectionStreamSubscription;
  String? subscribe_data;
  var response;
  scan() async {
    PermissionStatus locationPermission = await Permission.location.request();
    PermissionStatus bleScan = await Permission.bluetoothScan.request();
    PermissionStatus bleConnect = await Permission.bluetoothConnect.request();
    _device_t.clear();
    _streamSubscription?.cancel();
    _streamSubscription = flutterReactiveBle.scanForDevices(
        withServices:[],
        scanMode: ScanMode.lowLatency).listen((device) {
      if (device.id != "" && (_device_t.where((element) => element.id == device.id).isEmpty)) {
          _dataController.sink.add(_device_t);
          _device_t.add(device);
      }
    }, onError: (err) {
      print("$err");
    });
  }

  connect(String id) {
    _connectionStreamSubscription = flutterReactiveBle.connectToDevice(
    id: id,
    servicesWithCharacteristicsToDiscover: {
      Uuid.parse("2000"):[
        Uuid.parse("2001"),
        Uuid.parse("2002"),
        Uuid.parse("2003"),
        Uuid.parse("2004"),
      ],
    },
    connectionTimeout: const Duration(seconds: 3),).listen((connectionState) {
    if (connectionState.connectionState == DeviceConnectionState.connected) {
      print(" connectionState=${connectionState.deviceId}");
    }
    // Handle connection state updates
  }, onError: (Object error) {
    print("error=$error");
    // Handle a possible error
  });
  }

  subscribe_read(Uuid serviceUuid,Uuid characteristicUuid,String id) async{
    final characteristic = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: characteristicUuid, deviceId: id);
    flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      subscribe_data=hex.encoder.convert(data);
      subscribe_data=subscribe_data!.substring(0,2)+"-"+subscribe_data!.substring(2,4)+"-"+subscribe_data!.substring(4,6)+"-"+subscribe_data!.substring(6,8);
      update();
      // code to handle incoming data
    }, onError: (dynamic error) {
      // code to handle errors
    });
  }
  read(Uuid serviceUuid,Uuid characteristicUuid,String id) async{
    final characteristic = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: characteristicUuid, deviceId: id);
    final response = await flutterReactiveBle.readCharacteristic(characteristic);
    return response;
  }
  write(id, int val){
    if(val == 1){
      val=0x01;
      write_withoutresponse(Uuid.parse("2000"), Uuid.parse("2001"), id, val);
    }
    else{
      val=0x00;
      write_withoutresponse(Uuid.parse("2000"), Uuid.parse("2001"), id, val);
    }
  }
  write_withoutresponse(Uuid serviceUuid,Uuid characteristicUuid,String id,int val)async{
    final characteristic = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: characteristicUuid, deviceId: id);
    flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: [val]);
    response=await read(serviceUuid,characteristicUuid,id);
    print("${response}");
    update();
  }
}

Widget scaffold_draw_set(){
  return Drawer(
    child: ListView(
      children: const [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
         ListTile(
           leading: Icon(Icons.message),
           title: Text('1'),
         ),
      ],
    ),
  );
}

abstract class AppPages {
  static final pages = [
    GetPage(
      name: "/",
      page: () => const MyHomePage(),
    ),
    GetPage(
      name: "/Connect_page",
      page: () =>  Connect_page(),
    ),
  ];
}