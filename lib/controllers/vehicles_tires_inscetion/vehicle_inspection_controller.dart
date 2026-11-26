import 'package:emtrack/models/vehicles_tires_inscetion/vehicle_inspection_model.dart';
import 'package:emtrack/services/vehicles_tires_inscetion/vehicle_inspection_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

class VehicleInspectionController extends GetxController {
  final service = VehicleInspectionService();

  var vehicles = <VehicleInspectionModel>[].obs;
  var filteredList = <VehicleInspectionModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchData();
    super.onInit();
  }

  void fetchData() async {
    isLoading.value = true;
    try {
      vehicles.value = await service.fetchVehicles();
      filteredList.assignAll(vehicles);
    } catch (e) {
      debugPrint('[VehicleInspCtrl] fetchData EXCEPTION -> $e');
      vehicles.clear();
      filteredList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(vehicles);
    } else {
      filteredList.assignAll(
        vehicles.where(
          (e) =>
              e.asset.toLowerCase().contains(query.toLowerCase()) ||
              e.vehicleId.toString().contains(query),
        ),
      );
    }
  }

  void updateStatus(VehicleInspectionModel model, String status) {
    model.status = status;
    filteredList.refresh();
  }
}
