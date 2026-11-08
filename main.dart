import 'dart:async';
import 'dart:math';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(const MistressAlarmApp());
}

class MistressAlarmApp extends StatelessWidget {
  const MistressAlarmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Mistress Alarm', debugShowCheckedModeBanner: false, theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffb51f36), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xff100c0e), useMaterial3: true), home: const AlarmHome());
}

class AlarmHome extends StatefulWidget { const AlarmHome({super.key}); @override State<AlarmHome> createState() => _AlarmHomeState(); }
class _AlarmHomeState extends State<AlarmHome> {
  List<AlarmSettings> alarms = [];
  StreamSubscription<AlarmSettings>? subscription;
  AlarmSettings? ringing;
  final messages = ['Rise and shine. Your queen is waiting.', 'No more dreaming. Up, darling.', 'Your orders are simple: wake, stretch, shine.', 'The day belongs to those who rise on command.'];
  @override void initState() { super.initState(); refresh(); subscription = Alarm.ringing.listen((a) { if (mounted) setState(() => ringing = a); }); }
  @override void dispose() { subscription?.cancel(); super.dispose(); }
  Future<void> refresh() async { final a = await Alarm.getAlarms(); if (mounted) setState(() => alarms = a..sort((x,y)=>x.dateTime.compareTo(y.dateTime))); }
  Future<void> addAlarm(TimeOfDay time, String label) async {
    final notification = await Permission.notification.request();
    if (!mounted) return;
    if (!notification.isGranted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Allow notifications so your alarm can alert you.'))); return; }
    final now=DateTime.now(); var when=DateTime(now.year,now.month,now.day,time.hour,time.minute); if (!when.isAfter(now)) when=when.add(const Duration(days:1));
    final id=DateTime.now().millisecondsSinceEpoch.remainder(1<<31);
    try { await Alarm.set(alarmSettings: AlarmSettings(id:id,dateTime:when,assetAudioPath:'assets/alarm.mp3',loopAudio:true,vibrate:true,volume:1.0,fadeDuration:0,notificationTitle:'Mistress is calling',notificationBody:label.trim().isEmpty?messages[Random().nextInt(messages.length)]:label.trim(),enableNotificationOnKill:true)); await refresh(); }
    catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not set alarm: $e'))); }
  }
  Future<void> dismiss() async { final a=ringing; if(a!=null) await Alarm.stop(a.id); if(mounted) setState(()=>ringing=null); await refresh(); }
  Future<void> showAdd() async { final picked=await showTimePicker(context:context,initialTime:TimeOfDay.now()); if(picked==null||!mounted)return; final c=TextEditingController(text:'Rise and shine'); final label=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Your command'),content:TextField(controller:c,decoration:const InputDecoration(hintText:'A short wake-up message')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('CANCEL')),FilledButton(onPressed:()=>Navigator.pop(context,c.text),child:const Text('SET ALARM'))])); if(label!=null) await addAlarm(picked,label); }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('MISTRESS  /  ALARM',style:TextStyle(letterSpacing:2,fontWeight:FontWeight.bold)),centerTitle:true),body:SafeArea(child:Column(children:[Container(width:double.infinity,padding:const EdgeInsets.all(24),child:const Column(children:[Icon(Icons.bedtime_outlined,size:44,color:Color(0xffd84b62)),SizedBox(height:12),Text('Wake on your terms.',style:TextStyle(fontSize:23,fontWeight:FontWeight.w600)),SizedBox(height:6),Text('Set the time. Choose your command. Own your morning.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60))])),if(ringing!=null) Card(color:const Color(0xff651c2a),margin:const EdgeInsets.all(16),child:ListTile(title:Text(ringing!.notificationBody??'Time to rise'),subtitle:const Text('Your alarm is ringing'),trailing:FilledButton(onPressed:dismiss,child:const Text('I’M UP')))),Expanded(child:alarms.isEmpty?const Center(child:Text('No alarms yet. Tap below to set your first.')):ListView.builder(itemCount:alarms.length,itemBuilder:(context,i){final a=alarms[i];return Card(margin:const EdgeInsets.symmetric(horizontal:16,vertical:6),child:ListTile(leading:const Icon(Icons.alarm,color:Color(0xffd84b62)),title:Text(TimeOfDay.fromDateTime(a.dateTime).format(context),style:const TextStyle(fontSize:24)),subtitle:Text('${a.notificationBody??'Rise and shine'}  •  ${a.dateTime.month}/${a.dateTime.day}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await Alarm.stop(a.id);await refresh();})));})),Padding(padding:const EdgeInsets.all(18),child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:showAdd,icon:const Icon(Icons.add_alarm),label:const Padding(padding:EdgeInsets.all(14),child:Text('SET AN ALARM')))))])));
}
