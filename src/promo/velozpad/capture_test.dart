// 사이트 광고 이미지용 앱 화면 캡처 — VelozPad (macrokeyboard 저장소의 app/ 에서 돌린다).
//
// 원본: huhphilgoo.github.io/src/promo/velozpad/capture_test.dart
// 쓰는 법은 그 폴더의 README 참고. 앱 저장소에는 커밋하지 않는다.
//
//   cp <사이트>/src/promo/velozpad/capture_test.dart app/test/zz_promo_shots_test.dart
//   for l in ko en ja es; do SHOT_LANG=$l SHOT_DIR=<사이트>/src/promo/velozpad/raw \
//     flutter test test/zz_promo_shots_test.dart; done
//   rm app/test/zz_promo_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrokeyboard/l10n/app_localizations.dart';
import 'package:macrokeyboard/models/button_style_catalog.dart';
import 'package:macrokeyboard/models/profile_presets.dart';
import 'package:macrokeyboard/providers/pad_provider.dart';
import 'package:macrokeyboard/services/language_store.dart';
import 'package:macrokeyboard/theme/app_theme.dart';
import 'package:macrokeyboard/widgets/button_editor_sheet.dart';
import 'package:macrokeyboard/widgets/device_case.dart';
import 'package:macrokeyboard/widgets/key_deck.dart';
import 'package:mk_protocol/mk_protocol.dart';
import 'package:provider/provider.dart';

final lang = Platform.environment['SHOT_LANG'] ?? 'ko';
final out = Platform.environment['SHOT_DIR'] ?? '/tmp';

// 테스트에는 시스템 글꼴이 없어 글자가 네모가 된다. 기기가 쓰는 글꼴을 싣는다.
const fonts = {
  'ko': '/System/Library/Fonts/AppleSDGothicNeo.ttc',
  'ja': '/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc',
  'en': '/System/Library/Fonts/SFNS.ttf',
  'es': '/System/Library/Fonts/SFNS.ttf',
};

Future<void> loadFonts() async {
  final bytes = File(fonts[lang]!).readAsBytesSync();
  for (final family in ['Roboto', 'FlutterTest']) {
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }
  final menlo = File('/System/Library/Fonts/Menlo.ttc').readAsBytesSync();
  await (FontLoader('Menlo')..addFont(Future.value(ByteData.view(menlo.buffer))))
      .load();
  // 아이콘도 글꼴이다. Flutter 가 설치된 곳에서 찾는다.
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '/Users/philgooheo/Documents/develop/flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf')
      .readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(icons.buffer))))
      .load();
}

/// 글꼴을 지정하지 않은 글자(제목·채운 버튼)도 실어 둔 글꼴로 그리게 한다.
ThemeData theme() {
  final t = AppTheme.build();
  final filled = t.filledButtonTheme.style!;
  final filledText = filled.textStyle!.resolve({})!;
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: t.appBarTheme.copyWith(
        titleTextStyle:
            t.appBarTheme.titleTextStyle!.copyWith(fontFamily: 'Roboto')),
    filledButtonTheme: FilledButtonThemeData(
        style: filled.copyWith(
            textStyle: WidgetStatePropertyAll(
                filledText.copyWith(fontFamily: 'Roboto')))),
  );
}

Widget app(Widget home) => ChangeNotifierProvider(
      create: (_) => PadProvider(),
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: LanguageStore.supported.map(Locale.new).toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: theme(),
        home: home,
      ),
    );

/// 골든은 1배율로만 남는다. 2배율 PNG 로 직접 저장한다.
Future<void> shoot(WidgetTester tester, Finder f, String name) async {
  RenderObject node = tester.renderObject(f);
  while (node is! RenderRepaintBoundary) {
    node = node.parent!;
  }
  final boundary = node;
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$out/${name}_$lang.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void landscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1688, 780); // 가로 폰 844×390
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  final l = AppLocalizations(lang);

  for (final (tag, preset) in [
    ('pad', l.presetVideo),
    ('pad_ps', l.presetPhotoshop),
  ]) {
    testWidgets(tag, (tester) async {
      await loadFonts();
      landscapePhone(tester);
      final profile =
          ProfilePresets.all(l).firstWhere((p) => p.name == preset).build();
      await tester.pumpWidget(app(Scaffold(
        backgroundColor: AppColors.shell,
        body: SafeArea(
          child: DeviceCase(
            child: KeyDeck(
              profile: profile,
              enabled: true,
              rejections: const {},
              isFlashing: (_) => false,
              onPress: (_) {},
              onEditSlot: (_) {},
              onMove: (a, b) {},
              onKnob: (_) {},
              onKnobPress: () {},
              onEditKnob: () {},
              onClearSlot: (_) {},
              organizing: false,
              onOrganizingChanged: (_) {},
            ),
          ),
        ),
      )));
      await tester.pump(const Duration(milliseconds: 200));
      await shoot(tester, find.byType(Scaffold).first, tag);
    });
  }

  // 편집 화면 예시는 ⌘C — ⇧ 는 일본어 글꼴이 가는 화살표로 그려서 피했다
  testWidgets('editor', (tester) async {
    await loadFonts();
    landscapePhone(tester);
    await tester.pumpWidget(app(Scaffold(
      backgroundColor: AppColors.shell,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.raised,
          child: ButtonEditorSheet(
            initial: MacroButtonDef(
              id: 'x',
              label: l.btnCopy,
              icon: 'copy',
              colorValue: ButtonStyleCatalog.colors[0],
              action: const HotkeyAction(keyCode: 8, modifiers: ['cmd']),
            ),
          ),
        ),
      ),
    )));
    await tester.pump(const Duration(milliseconds: 150));
    await shoot(tester, find.byType(Scaffold).first, 'editor');
  });
}
