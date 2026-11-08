import 'dart:async';
import 'dart:math';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Alarm.init();
  runApp(const FemdomAlarmApp());
}

class FemdomAlarmApp extends StatelessWidget {
  const FemdomAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Femdom Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B0000),
          secondary: Color(0xFFB22222),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlarmSettings> alarms = [];
  StreamSubscription? ringSub;

  final List<String> mistressMessages = [
    "Wake up, slave. Mistress is waiting.",
    "On your knees. Now.",
    "You will rise when I say so.",
    "Good morning, pet. Serve.",
    "Obey. Get up.",
    "Your body belongs to me. Rise.",
    "No more sleep. Kneel.",
    "Mistress demands your attention.",
    "Wake. Submit. Serve.",
    "You are late already. Move.",
  ];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    ringSub = Alarm.ringing.listen((_) {
      // Alarm is ringing - show full screen if needed
    });
  }

  @override
  void dispose() {
    ringSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final list = await Alarm.getAlarms();
    setState(() => alarms = list);
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> _setAlarm(TimeOfDay time, String label) async {
    await _requestPermissions();

    final now = DateTime.now();
    var dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (dateTime.isBefore(now)) {
      dateTime = dateTime.add(const Duration(days: 1));
    }

    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/alarm.mp3', // user can replace
      loopAudio: true,
      vibrate: true,
      volume: 1.0,
      fadeDuration: 3.0,
      notificationTitle: "Mistress Calling",
      notificationBody: label.isNotEmpty ? label : mistressMessages[Random().nextInt(mistressMessages.length)],
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: settings);
    await _loadAlarms();
  }

  Future<void> _deleteAlarm(int id) async {
    await Alarm.stop(id);
    await _loadAlarms();
  }

  void _showAddAlarmSheet() {
    TimeOfDay selectedTime = TimeOfDay.now();
    String label = "Kneel";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Set Alarm",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB22222),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      selectedTime.format(context),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
                    ),
                    trailing: const Icon(Icons.access_time, color: Color(0xFFB22222)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF8B0000),
                                surface: Color(0xFF1A1A1A),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setModalState(() => selectedTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Command / Label",
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: "Kneel, Serve, Obey...",
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => label = v,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _setAlarm(selectedTime, label);
                        Navigator.pop(context);
                      },
                      child: const Text("COMMAND IT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0000), Color(0xFF0D0D0D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "MISTRESS",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 6,
                      color: Color(0xFFB22222),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ALARM",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You will wake when I decide",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Alarm list
            Expanded(
              child: alarms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nightlight_round, size: 64, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 16),
                          Text(
                            "No alarms set.\nMistress has not spoken yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.4), height: 1.5),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        final timeStr = DateFormat('HH:mm').format(alarm.dateTime);
                        final dateStr = DateFormat('EEE, MMM d').format(alarm.dateTime);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.3)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  alarm.notificationBody ?? "Obey",
                                  style: const TextStyle(color: Color(0xFFB22222)),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white38),
                              onPressed: () => _deleteAlarm(alarm.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAlarmSheet,
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("SET ALARM", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
