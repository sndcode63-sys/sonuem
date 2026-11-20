import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/edit_tyre/edit_tyre_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:http/http.dart' as http;

class EditTyreService {
  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }



  static Future<bool> updateTyre(EditTyreModel model) async {
    final Map<String, dynamic> payload = model.toJson();


    final treadKeys = ['removeAt', 'originalTread', 'purchasedTread',
      'outsideTread', 'middleTread', 'insideTread',
      'averageTreadDepth', 'currentTreadDepth'];
    for (final key in treadKeys) {
      if (payload[key] == null) payload[key] = 0.0;
    }

    if (payload['vehicleId'] == null || payload['vehicleId'] == 0) {
      payload.remove('vehicleId');
    }
    final vNum = payload['vehicleNumber'] as String?;
    if (vNum == null || vNum.isEmpty) {
      payload.remove('vehicleNumber');
    }

    final online = await _isOnline();

    if (online) {
      try {
        final cookie = await SecureStorage.getCookie();
        if (cookie == null || cookie.isEmpty) {
          throw Exception("Session expired. Please login again.");
        }

        final url = "${ApiConstants.baseUrl}/api/Tire";
        final body = jsonEncode(payload);

        final response = await http.put(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Cookie": cookie,
          },
          body: body,
        ).timeout(const Duration(seconds: 20));


        if (response.statusCode == 200 || response.statusCode == 201) {
          if (model.tireId != null) {
            await OfflineHiveService.saveTireDetailCache(
              model.tireId!,
              jsonEncode({'didError': false, 'model': payload}),
            );
            await OfflineHiveService.updateTyreInBox(model.tireId!, payload);
            await OfflineHiveService.patchTireInAllInspectionCaches(
                model.tireId!, payload);
          }
          return true;
        }

        if (response.statusCode == 401) {
          await SecureStorage.clearCookie();
          throw Exception("Session expired. Please login again.");
        }

        throw Exception("Failed to update tyre (${response.statusCode})");
      } catch (e) {
      }
    }

    bool mergedIntoCreate = false;
    if (model.tireId != null && model.tireId! < 0) {
      mergedIntoCreate = await OfflineHiveService.mergeIntoPendingCreateTyre(
        model.tireId!,
        payload,
      );
    }

    if (!mergedIntoCreate) {
      await OfflineHiveService.addPendingOperation(
        opType: 'updateTyre',
        payload: payload,
        endpoint: '/api/Tire',
        httpMethod: 'PUT',
      );
    }
    if (model.tireId != null) {
      await OfflineHiveService.saveTireDetailCache(
        model.tireId!,
        jsonEncode({'didError': false, 'model': payload}),
      );
      await OfflineHiveService.updateTyreInBox(model.tireId!, payload);
      await OfflineHiveService.patchTireInAllInspectionCaches(
          model.tireId!, payload);
    }
    return false;
  }

  static Future<EditTyreModel> getTyreById(int tireId) async {
    if (tireId < 0) {
      final hiveTyre = OfflineHiveService.getTyreById(tireId);
      if (hiveTyre != null) {
        return EditTyreModel(
          tireId:             hiveTyre.tireId,
          tireSerialNo:       hiveTyre.serialNumber,
          manufacturerId:     hiveTyre.manufacturerId,
          sizeId:             hiveTyre.tireSizeId,
          typeId:             hiveTyre.tireTypeId,
          dispositionId:      hiveTyre.dispositionId,
          vehicleId:          hiveTyre.vehicleId,
          wheelPosition:      hiveTyre.wheelPosition,
          outsideTread:       hiveTyre.outsideTread?.toDouble(),
          insideTread:        hiveTyre.insideTread?.toDouble(),
          currentPressure:    hiveTyre.currentPressure?.toDouble(),
          currentTreadDepth:  hiveTyre.currentTreadDepth?.toDouble(),
          currentHours:       hiveTyre.currentHours?.toDouble(),
          currentMiles:       hiveTyre.currentMiles?.toDouble(),
          originalTread:      hiveTyre.originalTread?.toDouble(),
          removeAt:           hiveTyre.removeAt?.toDouble(),
          purchasedTread:     hiveTyre.purchasedTread?.toDouble(),
          brandNo:            hiveTyre.brandNo,
          plyId:              hiveTyre.plyId,
          middleTread:        hiveTyre.middleTread?.toDouble(),
          purchaseCost:       hiveTyre.purchaseCost?.toDouble(),
          casingValue:        hiveTyre.casingValue?.toDouble(),
          fillCost:           hiveTyre.fillCost?.toDouble(),
          repairCost:         hiveTyre.repairCost?.toDouble(),
          retreadCost:        hiveTyre.retreadCost?.toDouble(),
          warrantyAdjustment: hiveTyre.warrantyAdjustment?.toDouble(),
          costAdjustment:     hiveTyre.costAdjustment?.toDouble(),
          soldAmount:         hiveTyre.soldAmount?.toDouble(),
          netCost:            hiveTyre.netCost?.toDouble(),
          loadRatingId:       hiveTyre.loadRatingId,
          speedRatingId:      hiveTyre.speedRatingId,
          compoundId:         hiveTyre.compoundId,
          indCodeId:          hiveTyre.indCodeId,
          fillTypeId:         hiveTyre.fillTypeId,
          lotNo:              hiveTyre.lotNo,
          poNo:               hiveTyre.poNo,
          evaluationNo:       hiveTyre.evaluationNo,
          registeredDate:     hiveTyre.registeredDate,
          tireStatusId:       hiveTyre.tireStatusId,
          tireStatusName:     hiveTyre.tireStatusName,
          starRatingId:       hiveTyre.starRatingId,
          mileageType:        hiveTyre.mileageType,
        );
      }
      throw Exception('Offline tyre data not found for tempId=$tireId');
    }

    final online = await _isOnline();

    if (online) {
      try {
        final cookie = await SecureStorage.getCookie();
        final url = "${ApiConstants.baseUrl}/api/Tire/GetById/$tireId";

        final response = await http.get(
          Uri.parse(url),
          headers: {"Accept": "application/json", "Cookie": cookie!},
        ).timeout(const Duration(seconds: 20));


        if (response.statusCode == 200) {
          await OfflineHiveService.saveTireDetailCache(tireId, response.body);
          final decoded = jsonDecode(response.body);
          final modelJson = decoded['model'];
          return EditTyreModel.fromJson(modelJson);
        }
      } catch (e) {
      }
    }

    final cached = OfflineHiveService.getTireDetailCache(tireId);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        final modelJson = decoded['model'] as Map<String, dynamic>;
        return EditTyreModel.fromJson(modelJson);
      } catch (e) {
      }
    }

    final hiveTyre = OfflineHiveService.getTyreById(tireId);
    if (hiveTyre != null) {
      return EditTyreModel(
        tireId:             hiveTyre.tireId,
        tireSerialNo:       hiveTyre.serialNumber,
        manufacturerId:     hiveTyre.manufacturerId,
        sizeId:             hiveTyre.tireSizeId,
        typeId:             hiveTyre.tireTypeId,
        dispositionId:      hiveTyre.dispositionId,
        vehicleId:          hiveTyre.vehicleId,
        wheelPosition:      hiveTyre.wheelPosition,
        outsideTread:       hiveTyre.outsideTread,
        insideTread:        hiveTyre.insideTread,
        currentPressure:    hiveTyre.currentPressure,
        currentTreadDepth:  hiveTyre.currentTreadDepth,
        currentHours:       hiveTyre.currentHours,
        currentMiles:       hiveTyre.currentMiles,
        originalTread:      hiveTyre.originalTread,
        removeAt:           hiveTyre.removeAt,
        purchasedTread:     hiveTyre.purchasedTread,
        brandNo:            hiveTyre.brandNo,
        plyId:              hiveTyre.plyId,
        middleTread:        hiveTyre.middleTread,
        purchaseCost:       hiveTyre.purchaseCost,
        casingValue:        hiveTyre.casingValue,
        fillCost:           hiveTyre.fillCost,
        repairCost:         hiveTyre.repairCost,
        retreadCost:        hiveTyre.retreadCost,
        warrantyAdjustment: hiveTyre.warrantyAdjustment,
        costAdjustment:     hiveTyre.costAdjustment,
        soldAmount:         hiveTyre.soldAmount,
        netCost:            hiveTyre.netCost,
        loadRatingId:       hiveTyre.loadRatingId,
        speedRatingId:      hiveTyre.speedRatingId,
        compoundId:         hiveTyre.compoundId,
        indCodeId:          hiveTyre.indCodeId,
        fillTypeId:         hiveTyre.fillTypeId,
        lotNo:              hiveTyre.lotNo,
        poNo:               hiveTyre.poNo,
        evaluationNo:       hiveTyre.evaluationNo,
        registeredDate:     hiveTyre.registeredDate,
        tireStatusId:       hiveTyre.tireStatusId,
        tireStatusName:     hiveTyre.tireStatusName,
      );
    }

    throw Exception('No offline data for tireId=$tireId. Please open this tyre while online first.');
  }}