import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/grand_parent_account_controller/grandparent_account_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';

class GrandparentAccountListView extends StatelessWidget {
  final c = Get.put(GrandparentAccountListController());

  GrandparentAccountListView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed('/home');
            }
          },
        ),
        backgroundColor: AppColors.primary,
        title: Text(
          t.grandparentAccountOptions,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(t),
            Expanded(child: _list(t)),
            _pagination(t),
          ],
        ),
      ),
    );
  }

  /// 🔍 Sirf Search Bar — ID, Name, OwnedBy, sab kuch
  Widget _searchBar(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Obx(() => TextField(
        cursorColor: Colors.red,
        decoration: InputDecoration(
          hintText: t.searchGrandparent, // "Search by name, ID, date..."
          prefixIcon: const Icon(Icons.search),
          // ✅ Clear button — jab kuch type ho
          suffixIcon: c.searchText.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => c.onSearch(''),
          )
              : null,
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
        onChanged: c.onSearch,
      )),
    );
  }

  /// 📋 List
  Widget _list(AppLocalizations t) {
    return Obx(() {
      return Stack(
        children: [
          if (c.loading.value)
            const Center(child: CircularProgressIndicator(color: Colors.red)),
          if (!c.loading.value && c.filteredAccounts.isEmpty)
            Center(child: Text(t.noDataAvailable)),
          ListView.builder(
            itemCount: c.filteredAccounts.length,
            itemBuilder: (context, index) {
              final a = c.filteredAccounts[index];
              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${t.id}: ${a.id}",
                            style:
                            const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: a.isActive ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a.isActive ? t.active : t.inactive,
                            style: TextStyle(
                              color: a.isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(t.ownedBy, a.ownedBy),
                      _row("Created By", a.createdBy),
                      _row("Create Date", a.createDate),
                      _row("Updated By", a.updatedBy),
                      _row("Update Date", a.updateDate),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text("$label: $value",
          style: const TextStyle(color: Colors.grey)),
    );
  }

  /// ⬅️ Pagination
  Widget _pagination(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: c.prevPage,
          ),
          Obx(() {
            if (c.totalRecords.value == 0) return const Text("0 - 0");
            final start = (c.currentPage.value - 1) * c.pageSize + 1;
            final end = start + c.accounts.length - 1;
            return Text("$start - $end of ${c.totalRecords.value}");
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: c.nextPage,
          ),
        ],
      ),
    );
  }
}