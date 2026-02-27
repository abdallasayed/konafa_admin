import 'dart:io';
void main() {
  var dir = Directory('android/app');
  if (!dir.existsSync()) return;
  for (var file in dir.listSync()) {
    if (file.path.contains('build.gradle')) {
      var f = File(file.path);
      var text = f.readAsStringSync();
      // تعديل جميع الصيغ الممكنة للرقم 19 إلى 21
      text = text.replaceAll('flutter.minSdkVersion', '21');
      text = text.replaceAll('minSdkVersion 19', 'minSdkVersion 21');
      text = text.replaceAll('minSdk = 19', 'minSdk = 21');
      f.writeAsStringSync(text);
      print('✅ تم اصطياد وتعديل الملف: ${file.path}');
    }
  }
}
