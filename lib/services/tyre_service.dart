import 'dart:convert';
import 'package:emtrack/models/tyre_model.dart';
import 'package:emtrack/models/tyre_responsive_model.dart';
import 'package:emtrack/models/view_tyre_response.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class     TyreService {
  static String get _getByIdUrl =>
      "${ApiConstants.baseUrl + ApiConstants.getTyresByAccount}/";

  Future<List<TyreModel>> getTyresByAccount(int accountId) async {
    try {

      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final url = Uri.parse("$_getByIdUrl$accountId");

      final response = await http.get(
        url,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );


      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final tyreResponse = TyreResponseModel.fromJson(decoded);

        if (tyreResponse.didError) {
          throw Exception(tyreResponse.errorMessage ?? "API returned an error");
        }


        return tyreResponse.model;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {

        Get.find<GlobalLogoutHandler>().forceLogout();
        return [];
      }
      throw Exception(
        "Failed to fetch tyre: ${response.statusCode} => ${response.body}",
      );
    } catch (e) {

      rethrow;
    }
  }

  Future<List<TyreModel>> getTyresById(int tireId) async {
    try {

      final response = await ApiService.getApi(
        endpoint: '${ApiConstants.getTyreById}$tireId',
      );

      if (response == null) {
        throw Exception("Empty API response");
      }

      final tyreResponse = TyreResponseModel.fromJson(response);

      if (tyreResponse.didError) {
        throw Exception(tyreResponse.errorMessage ?? "API returned an error");
      }


      return tyreResponse.model;
    } catch (e) {

      rethrow;
    }
  }

  Future<ViewModel> cloneTyresById(int tireId) async {
    try {
      final response = await ApiService.getApi(
        endpoint: '${ApiConstants.getTyreById}$tireId',
      );

      if (response != null) {
        try {
          await OfflineHiveService.saveTireDetailCache(
            tireId,
            jsonEncode({'didError': false, 'model': response['model'] ?? response}),
          );
        } catch (_) {}

        final tyreResponse = ViewTyreResponse.fromJson(response);
        if (tyreResponse.didError) {
          throw Exception(tyreResponse.errorMessage);
        }
        return tyreResponse.viewModel;
      }
    } catch (_) {
    }

    final cached = OfflineHiveService.getTireDetailCache(tireId);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        final modelJson = decoded['model'] as Map<String, dynamic>;
        return ViewModel.fromJson(modelJson);
      } catch (_) {
      }
    }

    final hiveTyre = OfflineHiveService.getTyreById(tireId);
    if (hiveTyre != null) {
      return ViewModel(
        tireId:         hiveTyre.tireId,
        tireSerialNo:   hiveTyre.serialNumber,
        manufacturerId: hiveTyre.manufacturerId,
        sizeId:         hiveTyre.tireSizeId,
        typeId:         hiveTyre.tireTypeId,
        dispositionId:  hiveTyre.dispositionId,
        vehicleId:      hiveTyre.vehicleId,
        wheelPosition:  hiveTyre.wheelPosition,
        outsideTread:   hiveTyre.outsideTread,
        insideTread:    hiveTyre.insideTread,
        currentPressure:   hiveTyre.currentPressure,
        currentTreadDepth: hiveTyre.currentTreadDepth,
        currentHours:   hiveTyre.currentHours,
        currentMiles:   hiveTyre.currentMiles,
        originalTread:  hiveTyre.originalTread,
        removeAt:       hiveTyre.removeAt,
        purchasedTread: hiveTyre.purchasedTread,
        tireStatusId:   hiveTyre.tireStatusId,
        mileageType:    hiveTyre.mileageType,
        starRatingId:   hiveTyre.starRatingId,
        purchaseCost:   hiveTyre.purchaseCost,
        casingValue:    hiveTyre.casingValue,
        fillCost:       hiveTyre.fillCost,
        repairCost:     hiveTyre.repairCost,
        retreadCost:    hiveTyre.retreadCost,
        warrantyAdjustment: hiveTyre.warrantyAdjustment,
        costAdjustment: hiveTyre.costAdjustment,
        soldAmount:     hiveTyre.soldAmount,
        netCost:        hiveTyre.netCost,
        loadRatingId:   hiveTyre.loadRatingId,
        speedRatingId:  hiveTyre.speedRatingId,
        compoundId:     hiveTyre.compoundId,
        indCodeId:      hiveTyre.indCodeId,
        fillTypeId:     hiveTyre.fillTypeId,
        lotNo:          hiveTyre.lotNo,
        poNo:           hiveTyre.poNo,
        evaluationNo:   hiveTyre.evaluationNo,
        registeredDate: hiveTyre.registeredDate != null ? DateTime.tryParse(hiveTyre.registeredDate!) : null,
      );
    }

    throw Exception('No offline data for tireId=$tireId. Please open this tyre while online first.');
  }
}
