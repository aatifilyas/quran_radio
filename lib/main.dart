import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. DEFINE YOUR STATIONS HERE
final List<Map<String, String>> stations = [
  {
    'lang': 'English',
    'url': 'http://64.23.135.87/listen/quran_urdu/radio.mp3',
    'id': '1',
  },
  {
    'lang': 'Urdu',
    'url': 'http://64.23.135.87/listen/quran_urdu/radio.mp3',
    'id': '2',
  },
  {
    'lang': 'Arabic',
    'url': 'http://64.23.135.87/listen/quran_urdu/radio.mp3',
    'id': '3',
  },
  {
    'lang': 'French',
    'url': 'http://64.23.135.87/listen/quran_urdu/radio.mp3',
    'id': '4',
  },
  // Add more languages here
];

Future<void> main() async {
  // Initialize Background Audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ), // Islamic Green
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  late AudioPlayer _player;
  int _selectedIndex = -1; // -1 means no language selected yet
  bool _isLoading = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadSavedStation();

    // Listen to player state changes (playing/paused/loading)
    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });
  }

  // Check if user has a saved language preference
  Future<void> _loadSavedStation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selected_station_index');

    if (savedIndex != null && savedIndex < stations.length) {
      setState(() {
        _selectedIndex = savedIndex;
      });
      _playStation(savedIndex);
    }
  }

  // Logic to switch station and play
  Future<void> _playStation(int index) async {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
    });

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_station_index', index);

    try {
      // Define the audio source with metadata for the lock screen
      final source = AudioSource.uri(
        Uri.parse(stations[index]['url']!),
        tag: MediaItem(
          id: stations[index]['id']!,
          album: "Live Radio",
          title: "Quran Translation: ${stations[index]['lang']}",
          artUri: Uri.parse(
            "https://i.imgur.com/7S8Z5XN.png",
          ), // Placeholder image
        ),
      );

      await _player.setAudioSource(source);
      _player.play();
    } catch (e) {
      ("Error loading stream: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no language is selected, show the Selection Screen
    if (_selectedIndex == -1) {
      return _buildLanguageSelectionScreen();
    }

    // Otherwise show the Player Screen
    return _buildPlayerScreen();
  }

  Widget _buildLanguageSelectionScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Language")),
      body: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.radio, color: Colors.green),
              title: Text(
                stations[index]['lang']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _playStation(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerScreen() {
    final currentStation = stations[_selectedIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Quran Radio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                setState(() => _selectedIndex = -1), // Go back to selection
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big Icon or Logo
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mosque, size: 100, color: Colors.green),
          ),
          const SizedBox(height: 40),

          // Station Name
          Text(
            currentStation['lang']!,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Text("Live Broadcast", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 60),

          // Play/Pause Button
          _isLoading
              ? const CircularProgressIndicator()
              : CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: IconButton(
                    iconSize: 40,
                    color: Colors.white,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (_isPlaying) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
