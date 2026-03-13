import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:align/Profile_customer.dart';
import 'package:align/Profile_suplier.dart';
import 'package:align/season.dart';

import 'leaf_identifier.dart';

class NavigatorMenu extends StatelessWidget {
  const NavigatorMenu({super.key});

  @override
  Widget build(BuildContext context) {

    final NavigationController controller = Get.put(NavigationController());

    return Scaffold(
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
      bottomNavigationBar: Obx(
            () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) {
            controller.selectedIndex.value = index;
            controller.update();
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.energy_savings_leaf), label: 'Identify Plant'),
            NavigationDestination(icon: Icon(Icons.access_time_filled), label: 'Season'),
            NavigationDestination(icon: Icon(Icons.account_circle), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;


  final Rx<Widget> profileScreen = Rx<Widget>(Container());


  late final List<Widget> screens;

  @override
  void onInit() {
    super.onInit();

    screens = [
      ObjectDetectionScreen(),
      Season(),
      Obx(() => profileScreen.value),
    ];
  }


  Future<void> navigateToProfile(String userId, String userType) async {
    if (userType == 'Buyer') {
      profileScreen.value = Profilecustomer(customerId: userId);
    } else if (userType == 'Supplier') {
      profileScreen.value = Profilesupplier(supplierId: userId, userId: '');
    }
    selectedIndex.value = 2;
  }
}
