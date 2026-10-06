import 'package:flutter/material.dart';

class BrandConfig {
  const BrandConfig._();

  static const committeeName = 'Jay Bhole Goshala Samiti';
  static const hindiCommitteeName = 'जय भोले गौशाला समिति';
  static const tagline = 'गौ सेवा • जीव सेवा • समाज सेवा';
  static const address =
      'ग्राम मेंहदौरा, तहसील पोरसा, जिला मुरैना, मध्यप्रदेश - 476115';
  static const phone = 'जानकारी जल्द जोड़ी जाएगी';
  static const whatsapp = 'जानकारी जल्द जोड़ी जाएगी';
  static const upi = 'जानकारी जल्द जोड़ी जाएगी';
  static const defaultUpiId = 'jaybholegoshala@upi';
  static String get effectiveUpiId =>
      (upi.isNotEmpty && !upi.contains('जल्द')) ? upi : defaultUpiId;
  static const registrationNumber = 'जानकारी जल्द जोड़ी जाएगी';
  static const logoAsset = 'assets/logo/jay_bhole_logo.png';

  static const primary = Color(0xFF2F6B45);
  static const secondary = Color(0xFF1F4F34);
  static const cream = Color(0xFFF7F8F2);
  static const leaf = Color(0xFFE7F1E5);
  static const orange = Color(0xFFE58B3A);
  static const ink = Color(0xFF243127);
  static const muted = Color(0xFF6B756D);
  static const border = Color(0xFFE0E8DE);
}
