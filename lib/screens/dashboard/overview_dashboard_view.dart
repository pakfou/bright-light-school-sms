import 'package:flutter/material.dart';
import 'package:school_management_app/screens/dashboard/overview_tab.dart';

class OverviewDashboardView extends StatelessWidget {
  final Function(int menuIndex)? onNavigate;
  final bool isAdmin;

  const OverviewDashboardView({
    super.key,
    this.onNavigate,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    return OverviewTab(
      isAdmin: isAdmin,
      onNavigate: (index, {int? subTab, bool? openAdd}) {
        onNavigate?.call(index);
      },
    );
  }
}
