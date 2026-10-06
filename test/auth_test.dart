import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jay_bhole_goshala/models/app_user.dart';
import 'package:jay_bhole_goshala/screens/dashboards/admin_dashboard_screen.dart';
import 'package:jay_bhole_goshala/screens/dashboards/role_dashboard_router.dart';
import 'package:jay_bhole_goshala/screens/dashboards/staff_dashboard_screen.dart';
import 'package:jay_bhole_goshala/screens/dashboards/user_dashboard_screen.dart';
import 'package:jay_bhole_goshala/services/firebase_backend.dart';

void main() {
  group('UserRole & AppUser mapping', () {
    test('UserRole.fromString correctly parses all roles', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('STAFF'), UserRole.staff);
      expect(UserRole.fromString('user'), UserRole.user);
      expect(UserRole.fromString('viewer'), UserRole.user);
      expect(UserRole.fromString('unknown'), UserRole.user);
      expect(UserRole.fromString(null), UserRole.user);
    });

    test('UserRole properties match permissions', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isStaff, isFalse);
      expect(UserRole.admin.isUser, isFalse);

      expect(UserRole.staff.isAdmin, isFalse);
      expect(UserRole.staff.isStaff, isTrue);
      expect(UserRole.staff.isUser, isFalse);

      expect(UserRole.user.isAdmin, isFalse);
      expect(UserRole.user.isStaff, isFalse);
      expect(UserRole.user.isUser, isTrue);
    });

    test('AppUser serialization and permission flags', () {
      const adminUser = AppUser(
        uid: 'admin_123',
        email: 'admin@goshala.org',
        name: 'Pradhan Ji',
        role: UserRole.admin,
      );
      expect(adminUser.canManageUsers, isTrue);
      expect(adminUser.canEditRecords, isTrue);

      const staffUser = AppUser(
        uid: 'staff_123',
        email: 'sevak@goshala.org',
        name: 'Sevak Ram',
        role: UserRole.staff,
      );
      expect(staffUser.canManageUsers, isFalse);
      expect(staffUser.canEditRecords, isTrue);

      const generalUser = AppUser(
        uid: 'user_123',
        email: 'bhakt@gmail.com',
        name: 'Shyam Bhakt',
        role: UserRole.user,
      );
      expect(generalUser.canManageUsers, isFalse);
      expect(generalUser.canEditRecords, isFalse);

      final json = generalUser.toJson();
      expect(json['role'], 'viewer'); // Firestore rule compatible

      final restored = AppUser.fromJson(json);
      expect(restored.role, UserRole.user);
      expect(restored.name, 'Shyam Bhakt');
    });

    test('AppUser.fromJson parses various admin attribute styles', () {
      final fromIsAdmin = AppUser.fromJson({
        'uid': 'adm_1',
        'email': 'admin1@test.com',
        'name': 'Admin One',
        'isAdmin': true,
      });
      expect(fromIsAdmin.role, UserRole.admin);
      expect(fromIsAdmin.isAdmin, isTrue);
      expect(fromIsAdmin.permissions, AppPermission.all);

      final fromUpperCase = AppUser.fromJson({
        'uid': 'adm_2',
        'email': 'admin2@test.com',
        'name': 'Admin Two',
        'role': 'ADMIN',
      });
      expect(fromUpperCase.role, UserRole.admin);
      expect(fromUpperCase.isAdmin, isTrue);

      final fromStaffRole = AppUser.fromJson({
        'uid': 'stf_1',
        'email': 'staff1@test.com',
        'name': 'Staff One',
        'role': 'staff',
        'permissions': [AppPermission.cows, AppPermission.feed],
      });
      expect(fromStaffRole.role, UserRole.staff);
      expect(fromStaffRole.isStaff, isTrue);
      expect(fromStaffRole.hasPermission(AppPermission.cows), isTrue);
      expect(fromStaffRole.hasPermission(AppPermission.finance), isFalse);

      final fromStaffWithFinance = AppUser.fromJson({
        'uid': 'stf_2',
        'email': 'staff2@test.com',
        'name': 'Staff Finance',
        'role': 'staff',
        'permissions': [AppPermission.finance],
      });
      expect(fromStaffWithFinance.hasPermission(AppPermission.finance), isTrue);
      expect(fromStaffWithFinance.isAdmin, isFalse);
    });
  });

  group('RoleDashboardRouter verification', () {
    test('routes admin to AdminDashboardScreen', () {
      const adminUser = AppUser(
        uid: 'admin_1',
        email: 'admin@test.com',
        name: 'Admin',
        role: UserRole.admin,
      );
      final widget = RoleDashboardRouter.getDashboard(adminUser);
      expect(widget, isA<AdminDashboardScreen>());
    });

    test('routes staff to StaffDashboardScreen', () {
      const staffUser = AppUser(
        uid: 'staff_1',
        email: 'staff@test.com',
        name: 'Staff',
        role: UserRole.staff,
      );
      final widget = RoleDashboardRouter.getDashboard(staffUser);
      expect(widget, isA<StaffDashboardScreen>());
    });

    test('routes user to UserDashboardScreen', () {
      const normalUser = AppUser(
        uid: 'user_1',
        email: 'user@test.com',
        name: 'User',
        role: UserRole.user,
      );
      final widget = RoleDashboardRouter.getDashboard(normalUser);
      expect(widget, isA<UserDashboardScreen>());
    });
  });

  group('Firebase error handling', () {
    test('userFriendlyAuthError translates known error codes', () {
      final invalidCred = FirebaseBackend.userFriendlyAuthError(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      expect(invalidCred, contains('गलत'));

      final wrongPass = FirebaseBackend.userFriendlyAuthError(
        FirebaseAuthException(code: 'wrong-password'),
      );
      expect(wrongPass, contains('Password'));

      final userNotFound = FirebaseBackend.userFriendlyAuthError(
        FirebaseAuthException(code: 'user-not-found'),
      );
      expect(userNotFound, contains('खाता नहीं मिला'));

      final netError = FirebaseBackend.userFriendlyAuthError(
        const SocketException('No route to host'),
      );
      expect(netError, contains('इंटरनेट'));
    });
  });
}
