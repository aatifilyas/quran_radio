
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quran_radio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([AudioPlayer, SharedPreferences])
void main() {
  late MockAudioPlayer mockPlayer;
  late MockSharedPreferences mockPrefs;
  late StreamController<PlayerState> playerStateController;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    mockPrefs = MockSharedPreferences();
    playerStateController = StreamController<PlayerState>();

    when(mockPrefs.getInt('selected_station_index')).thenReturn(null);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
    when(mockPlayer.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(mockPlayer.setAudioSource(any)).thenAnswer((_) async => const Duration(seconds: 1));
    when(mockPlayer.play()).thenAnswer((_) async {});
  });

  tearDown(() {
    playerStateController.close();
  });

  testWidgets('RadioHomePage initial state and navigation', (WidgetTester tester) async {
    // Initial state is idle
    playerStateController.add(PlayerState(false, ProcessingState.idle));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(prefs: mockPrefs, player: mockPlayer));

    // Verify that the initial screen is the language selection screen.
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    // Tap on the first language option.
    await tester.tap(find.byType(ListTile).first);
    await tester.pump(); // Process the tap

    // Simulate loading state
    playerStateController.add(PlayerState(true, ProcessingState.loading));
    await tester.pump(); // Show loading indicator

    // Verify loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Simulate ready state
    playerStateController.add(PlayerState(true, ProcessingState.ready));
    await tester.pump(); // Show player screen

    // Verify that we have navigated to the player screen.
    expect(find.text('Quran Radio'), findsOneWidget);
    expect(find.text(stations[0]['lang']!), findsOneWidget);

    // After loading, the player might be playing, so we check for the pause icon
    playerStateController.add(PlayerState(true, ProcessingState.ready));
    await tester.pump();
    
    // Simulate playing state
    playerStateController.add(PlayerState(true, ProcessingState.ready));
    await tester.pump();
    
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
