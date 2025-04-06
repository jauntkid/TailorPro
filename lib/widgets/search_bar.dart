import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onSearch;
  final TextEditingController? controller;

  const CustomSearchBar({
    Key? key,
    required this.hintText,
    required this.onSearch,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        style: TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: const Color(0xFFADAEBC)),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
