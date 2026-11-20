import 'dart:ui';

class TyreData {
  final String serial, percent, p, to, tm, ti, miles;
  final String? brandNo;
  final Color borderColor, percentColor;

  TyreData({
    required this.serial,
    this.brandNo,
    required this.percent,
    required this.percentColor,
    required this.borderColor,
    required this.p,
    required this.to,
    required this.tm,
    required this.ti,
    required this.miles,
  });
}