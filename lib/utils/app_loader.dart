import 'package:flutter/material.dart';

class AppLoader1 extends StatelessWidget {
  final bool isLoading;

  const AppLoader1({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withAlpha(26),
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Colors.red,
            strokeWidth: 6,
          ),
        ),
      ),
    );
  }

}