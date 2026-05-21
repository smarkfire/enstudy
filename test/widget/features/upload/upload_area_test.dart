import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enstudy/features/upload/presentation/widgets/upload_area.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('UploadArea组件', () {
    group('渲染相机图标', () {
      testWidgets('显示camera_alt_outlined图标', (tester) async {
        await tester.pumpApp(
          const UploadArea(),
        );

        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      });
    });

    group('渲染提示文字', () {
      testWidgets('显示主提示文字', (tester) async {
        await tester.pumpApp(
          const UploadArea(),
        );

        expect(find.text('点击上传图片'), findsOneWidget);
      });

      testWidgets('显示格式提示文字', (tester) async {
        await tester.pumpApp(
          const UploadArea(),
        );

        expect(find.text('支持 JPG、PNG、WEBP 格式'), findsOneWidget);
      });
    });

    group('点击回调', () {
      testWidgets('点击时触发onTap回调', (tester) async {
        var tapped = false;
        await tester.pumpApp(
          UploadArea(
            onTap: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(find.byType(UploadArea));
        expect(tapped, isTrue);
      });

      testWidgets('未设置onTap时点击不报错', (tester) async {
        await tester.pumpApp(
          const UploadArea(),
        );

        await tester.tap(find.byType(UploadArea));
      });
    });
  });
}
