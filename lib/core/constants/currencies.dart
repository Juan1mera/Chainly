import 'package:flutter/material.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final IconData icon;

  const CurrencyInfo(this.code, this.name, this.icon);
}

class Currencies {
  static final List<CurrencyInfo> supported = [
    CurrencyInfo('USD', 'Dólar estadounidense', Icons.attach_money),
    CurrencyInfo('EUR', 'Euro', Icons.euro),
    CurrencyInfo('GBP', 'Libra esterlina', Icons.currency_pound),
    CurrencyInfo('COP', 'Peso colombiano', Icons.paid),
    CurrencyInfo('MXN', 'Peso mexicano', Icons.money),
    CurrencyInfo('BRL', 'Real brasileño', Icons.currency_exchange_outlined),
    CurrencyInfo('JPY', 'Yen japonés', Icons.currency_yen),
    CurrencyInfo('INR', 'Rupia india', Icons.currency_rupee),
    CurrencyInfo('RUB', 'Rublo ruso', Icons.currency_ruble),
    CurrencyInfo('CNY', 'Yuan chino', Icons.currency_yuan),
  ];

  static IconData getIcon(String code) {
    return supported.where((c) => c.code == code).firstOrNull?.icon ?? Icons.attach_money;
  }

  static List<String> get codes => supported.map((c) => c.code).toList();
}