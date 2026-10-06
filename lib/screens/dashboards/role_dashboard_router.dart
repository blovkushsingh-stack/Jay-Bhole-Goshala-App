import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import 'admin_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';
import 'user_dashboard_screen.dart';

class RoleDashboardRouter {
  const RoleDashboardRouter._();

  static Widget getDashboard(AppUser user) {
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboardScreen(user: user);
      case UserRole.staff:
        return StaffDashboardScreen(user: user);
      case UserRole.user:
        return UserDashboardScreen(user: user);
    }
  }

  static void openDashboard(BuildContext context, AppUser user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => getDashboard(user)),
      (route) => false,
    );
  }

  static void pushDashboard(BuildContext context, AppUser user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => getDashboard(user)));
  }
}
