import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NotificationService {
  // ستقوم باستبدال هذه القيم لاحقاً من حسابك في OneSignal
  static const String _appId = "2d506dcb-8201-4f28-9c4e-6aeff5c6245f";
  static const String _restApiKey = "Os_v2_app_fvig3s4cafhsrhconlx7lrrel73l6n4himbe2uvwdkg75xob6g7v7cd3srm7ma7pon3ws4gn4hfxi6qb74no2op2mpwmb43i57irlja";

  static Future<void> sendNotification({required String targetOneSignalId, required String title, required String bodyMsg}) async {
    if (_appId.contains("ضع_الـ")) return; // حماية لكي لا يعمل الكود قبل وضع مفاتيحك الحقيقية

    try {
      var url = Uri.parse('https://onesignal.com/api/v1/notifications');
      var body = jsonEncode({
        "app_id": _appId,
        "include_subscription_ids": [targetOneSignalId], // إرسال الإشعار لهاتف هذا الشخص فقط
        "headings": {"en": title, "ar": title},
        "contents": {"en": bodyMsg, "ar": bodyMsg},
      });
      var headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Basic $_restApiKey"
      };
      await http.post(url, body: body, headers: headers);
      debugPrint("تم إرسال الإشعار بنجاح!");
    } catch (e) {
      debugPrint("خطأ في إرسال الإشعار: $e");
    }
  }
}
