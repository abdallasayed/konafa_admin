import 'dart:io';
void main() {
  var file = File('android/build.gradle');
  if (file.existsSync()) {
    var text = file.readAsStringSync();
    // هذا السطر يبحث عن إعدادات الكوتلن ويغيرها إلى 1.9.24 فوراً مهما كان القديم
    text = text.replaceAll(RegExp(r"ext\.kotlin_version\s*=\s*['\"].*?['\"]"), "ext.kotlin_version = '1.9.24'");
    file.writeAsStringSync(text);
    print('✅ تم اصطياد وتعديل إصدار Kotlin إلى 1.9.24 بنجاح!');
  } else {
    print('❌ لم يتم العثور على الملف!');
  }
}
