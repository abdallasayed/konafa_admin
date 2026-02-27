import 'dart:io';
void main() {
  var dir = Directory('.github/workflows');
  if (!dir.existsSync()) return;
  for (var file in dir.listSync()) {
    if (file.path.endsWith('.yml')) {
      var f = File(file.path);
      var text = f.readAsStringSync();
      // إضافة أمر تعديل الكوتلن بجوار أمر تعديل الإصدار السابق
      text = text.replaceAll('&& flutter build apk', '&& sed -i "s/1.7.1/1.9.24/g" android/build.gradle && flutter build apk');
      f.writeAsStringSync(text);
      print('✅ تم إضافة أمر تحديث Kotlin إلى السيرفر بنجاح!');
    }
  }
}
