import 'dart:io';
import 'dart:ui' as ui;

import 'package:dynamotivation_software_hub_ubuntu/app.dart';
import 'package:dynamotivation_software_hub_ubuntu/presentation/controllers/hub_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

import 'yaru_window_mock.dart';

Future<void> loadRealFonts() async {
  // 1. Ubuntu text fonts
  final yaruFontDir = Directory(
    'C:/Users/Daniel/AppData/Local/Pub/Cache/hosted/pub.dev/yaru-10.2.0/assets/fonts',
  );
  if (yaruFontDir.existsSync()) {
    for (final family in ['Ubuntu', 'packages/yaru/Ubuntu']) {
      final fontLoader = FontLoader(family);
      for (final fontName in [
        'Ubuntu-R.ttf',
        'Ubuntu-B.ttf',
        'Ubuntu-M.ttf',
        'Ubuntu-L.ttf',
      ]) {
        final file = File('${yaruFontDir.path}/$fontName');
        if (file.existsSync()) {
          final data = file.readAsBytesSync();
          fontLoader.addFont(Future.value(ByteData.view(data.buffer)));
        }
      }
      await fontLoader.load();
    }
  }

  // 2. Yaru icon font
  final yaruIconFile = File(
    'C:/Users/Daniel/AppData/Local/Pub/Cache/hosted/pub.dev/yaru-10.2.0/assets/yaru_icons.otf',
  );
  if (yaruIconFile.existsSync()) {
    for (final family in ['YaruIcons', 'packages/yaru/YaruIcons']) {
      final iconLoader = FontLoader(family);
      final data = yaruIconFile.readAsBytesSync();
      iconLoader.addFont(Future.value(ByteData.view(data.buffer)));
      await iconLoader.load();
    }
  }

  // 3. MaterialIcons
  final matFontFile = File(
    'C:/Users/Daniel/flutterSDK/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (matFontFile.existsSync()) {
    final matLoader = FontLoader('MaterialIcons');
    final data = matFontFile.readAsBytesSync();
    matLoader.addFont(Future.value(ByteData.view(data.buffer)));
    await matLoader.load();
  }

  // 4. Roboto
  final robotoDir = Directory(
    'C:/Users/Daniel/flutterSDK/flutter/bin/cache/artifacts/material_fonts',
  );
  if (robotoDir.existsSync()) {
    final robotoLoader = FontLoader('Roboto');
    for (final fontName in [
      'roboto-regular.ttf',
      'roboto-bold.ttf',
      'roboto-medium.ttf',
    ]) {
      final file = File('${robotoDir.path}/$fontName');
      if (file.existsSync()) {
        final data = file.readAsBytesSync();
        robotoLoader.addFont(Future.value(ByteData.view(data.buffer)));
      }
    }
    await robotoLoader.load();
  }

  // 5. Segoe UI
  final segoeFile = File('C:/Windows/Fonts/segoeui.ttf');
  if (segoeFile.existsSync()) {
    final segoeLoader = FontLoader('Segoe UI');
    final data = segoeFile.readAsBytesSync();
    segoeLoader.addFont(Future.value(ByteData.view(data.buffer)));
    await segoeLoader.load();
  }
}

void main() {
  const artifactDir =
      'C:/Users/Daniel/.t3/userdata/providers/antigravity/ac0a3dfd6dddb20962cecff6ee5fe65e19d3923be20e52c5ab52ff877f7e4c32/antigravity-acp/brain/72089a68-6a50-4547-8dbd-c885b5d7629d';
  const repoScreenshotsDir =
      'D:/source/repos/DynamotivationSoftwareHub/apps/ubuntu/screenshots';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRealFonts();
  });

  Future<void> captureScreen({
    required WidgetTester tester,
    required String fileName,
    bool isDark = false,
    bool isSettings = false,
  }) async {
    tester.view.physicalSize = const ui.Size(1060, 780);
    tester.view.devicePixelRatio = 1.0;

    final controller = HubController(
      HubUseCases(
        InMemoryPackageRepository(refreshDelay: Duration.zero),
        InMemorySettingsRepository(),
      ),
    );
    await controller.load(preferredId: 'geo-background-generator');

    if (isDark) {
      await controller.updateSettings(
        controller.settings.copyWith(themeMode: AppThemeMode.dark),
      );
    } else {
      await controller.updateSettings(
        controller.settings.copyWith(themeMode: AppThemeMode.light),
      );
    }

    final repaintKey = GlobalKey();

    mockYaruWindowChannel();

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintKey,
        child: DynamotivationUbuntuApp(
          controller: controller,
          initialSettingsOpen: isSettings,
        ),
      ),
    );

    // Give real async IO time to decode images
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final artifactFile = File('$artifactDir/$fileName');
      await artifactFile.writeAsBytes(bytes);

      final repoFile = File('$repoScreenshotsDir/$fileName');
      await repoFile.writeAsBytes(bytes);

      print('Rendered: $fileName (${bytes.length} bytes)');
    });
  }

  testWidgets('Render Ubuntu Frontend Screenshots with Real Fonts and Icons', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);

    await captureScreen(
      tester: tester,
      fileName: 'ubuntu_frontend_main.png',
      isDark: false,
      isSettings: false,
    );

    await captureScreen(
      tester: tester,
      fileName: 'ubuntu_frontend_dark.png',
      isDark: true,
      isSettings: false,
    );

    await captureScreen(
      tester: tester,
      fileName: 'ubuntu_frontend_settings.png',
      isDark: false,
      isSettings: true,
    );
  });
}
