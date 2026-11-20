import 'package:get/get.dart';
import '../../models/grand_parent_account_model/grandparent_account_list_model.dart';
import '../../services/grand_parent_account_service/grandparent_account_list_service.dart';
class GrandparentAccountListController extends GetxController {
  final GrandparentAccountListService service = GrandparentAccountListService();

  RxList<GrandparentAccountList> accounts = <GrandparentAccountList>[].obs;
  RxBool loading = false.obs;
  RxString searchText = ''.obs;
  RxInt currentPage = 1.obs;
  final int pageSize = 10;
  RxInt totalRecords = 0.obs;

  List<GrandparentAccountList> get filteredAccounts => accounts;

  int get totalPages => (totalRecords.value / pageSize).ceil();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    loading.value = true;
    try {
      final response = await service.fetchAccounts(
        page: currentPage.value,
        pageSize: pageSize,
        search: searchText.value.trim(),
      );
      accounts.value = response.items;
      totalRecords.value = response.totalCount;
    } catch (e) {
      accounts.clear();
    } finally {
      loading.value = false;
    }
  }

  void onSearch(String value) {
    searchText.value = value;
    currentPage.value = 1;
    fetchData();
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
      fetchData();
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchData();
    }
  }
}
