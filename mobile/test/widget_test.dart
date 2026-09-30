import 'package:flutter_test/flutter_test.dart';
import 'package:video_vault/app.dart';

void main() {
  testWidgets('App opens on reels with VideoVault branding', (tester) async {
    await tester.pumpWidget(const VideoVaultApp());
    await tester.pump();
    expect(find.text('VideoVault'), findsOneWidget);
  });
}
