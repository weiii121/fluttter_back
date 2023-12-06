import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:myproject/main.dart';

// ignore: must_be_immutable
class Connect_page extends StatelessWidget {
  Connect_page({super.key});
  String id = Get.arguments;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("SPIE"),
          centerTitle: true,
        ),
        drawer: scaffold_draw_set(),
        body: GetBuilder<BLEController>(
          init: BLEController(),
          builder: (controller) {
            return Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Center(child: Text("$id")),
                ElevatedButton(
                  onPressed: () => controller.subscribe_read(
                      Uuid.parse("2000"), Uuid.parse("2002"), id),
                  child: const Text("Notify"),
                ),
                Container(
                  child: Text("${controller.subscribe_data}"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.write(id, 1),
                      child: const Text("Write=1"),
                    ),
                    ElevatedButton(
                      onPressed: () => controller.write(id, 0),
                      child: const Text("Write=0"),
                    ),
                  ],
                ),
                Container(
                  child: Text("${controller.response}"),
                ),
              ],
            );
          },
        ));
  }
}
