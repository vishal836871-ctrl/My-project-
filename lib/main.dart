import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(backgroundColor: Colors.black, elevation: 0),
      ),
      home: SplashScreen(),
    );
  }
}

// 1. SPLASH - NAMASTE BOLEGA BHI + LIKHEGA BHI
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  FlutterTts tts = FlutterTts();
  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    await tts.setLanguage("hi-IN");
    await tts.setSpeechRate(0.45); // Awaaz achi aur saaf ke liye slow ki
    await tts.setPitch(1.0);
    await tts.speak("Namaste Ustad");
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences pref = await SharedPreferences.getInstance();
    bool isFirst = pref.getBool('isFirst') ?? true;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => isFirst
                ? OnboardingScreen()
                : HomeScreen(callName: pref.getString('callName') ?? 'Malik')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child: Text("NAMASTE",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5))),
    );
  }
}

// 2. ONBOARDING - EK-EK SAWAL
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  String mood = "Badhiya";
  String callName = "Malik";
  String lang = "Hindi";
  TimeOfDay time = TimeOfDay(hour: 20, minute: 0);
  FlutterTts tts = FlutterTts();

  speak(String text) async {
    await tts.setLanguage("hi-IN");
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    speak("Aap kaise hai Ustad?");
  }

  next() async {
    if (step == 0) {
      setState(() => step = 1);
      speak("Aapko kis naam se bulau? Malik, Ustad ya Sir?");
    } else if (step == 1) {
      setState(() => step = 2);
      speak("Bhasha kaunsi rakhu, Hindi ya English?");
    } else if (step == 2) {
      setState(() => step = 3);
      speak("Roz hisaab kis time puchu?");
    } else {
      save();
    }
  }

  save() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool('isFirst', false);
    await pref.setString('callName', callName);
    await pref.setString('lang', lang);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => HomeScreen(callName: callName)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (step == 0) ...[
              Text("Aap kaise hai?",
                  style: TextStyle(fontSize: 26, color: Colors.white)),
              SizedBox(height: 20),
              Wrap(
                  spacing: 10,
                  children: ["Badhiya hu", "Thoda Pareshan", "Mast"]
                      .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: mood == e,
                          onSelected: (_) {
                            setState(() => mood = e);
                          }))
                      .toList()),
            ],
            if (step == 1) ...[
              Text("Aapko kis naam se bulau?",
                  style: TextStyle(fontSize: 26, color: Colors.white)),
              SizedBox(height: 20),
              Wrap(
                  spacing: 10,
                  children: ["Malik", "Ustad", "Sir"]
                      .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: callName == e,
                          onSelected: (_) {
                            setState(() => callName = e);
                          }))
                      .toList()),
            ],
            if (step == 2) ...[
              Text("Bhasha Choose Karo",
                  style: TextStyle(fontSize: 26, color: Colors.white)),
              SizedBox(height: 20),
              Wrap(
                  spacing: 10,
                  children: ["Hindi", "English"]
                      .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: lang == e,
                          onSelected: (_) {
                            setState(() => lang = e);
                          }))
                      .toList()),
            ],
            if (step == 3) ...[
              Text("Hisaab ka Time Fix Karo",
                  style: TextStyle(fontSize: 26, color: Colors.white)),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () async {
                    var t = await showTimePicker(
                        context: context, initialTime: time);
                    if (t != null) setState(() => time = t);
                  },
                  child: Text("Time: ${time.format(context)}")),
            ],
            SizedBox(height: 40),
            ElevatedButton(
                onPressed: next,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: Size(double.infinity, 50)),
                child: Text(step == 3 ? "Shuru Karo" : "Aage Bado"))
          ],
        ),
      ),
    );
  }
}

// 3. HOME SCREEN - NO YELLOW, 3 ICON, AWAAZ
class HomeScreen extends StatefulWidget {
  final String callName;
  HomeScreen({required this.callName});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterTts tts = FlutterTts();
  SpeechToText speech = SpeechToText();
  List<String> hisaabList = [];
  String status = "";

  @override
  void initState() {
    super.initState();
    initVoice();
  }

  initVoice() async {
    await tts.setLanguage("hi-IN");
    await tts.setSpeechRate(0.44);
    await tts.speak("Chalo shuru karte hai ${widget.callName} Ji");
  }

  // Bol ke Hisaab
  startListening() async {
    bool avail = await speech.initialize();
    if (avail) {
      setState(() => status = "Sun raha hu...");
      speech.listen(onResult: (res) {
        setState(() => status = res.recognizedWords);
        if (res.finalResult) processCommand(res.recognizedWords);
      });
    }
  }

  processCommand(String text) async {
    text = text.toLowerCase();
    if (text.contains("pareshan") || text.contains("tension")) {
      tts.speak("Paani pi lo ${widget.callName} Ji, thoda walk kar lo");
    } else if (text.isNotEmpty) {
      setState(() => hisaabList.add(text));
      tts.speak("Ho gaya ${widget.callName} Ji, likh diya");
    }
    setState(() => status = "");
  }

  // WhatsApp
  sendWhatsApp() async {
    var url = Uri.parse(
        "https://wa.me/?text=${Uri.encodeComponent("Namaste, aaj ka hisaab bhej diya hai")}");
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Haath se likhna
  manualAdd() {
    TextEditingController c = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title:
                  Text("Haath se likho", style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: c,
                  style: TextStyle(color: Colors.white),
                  decoration:
                      InputDecoration(hintText: "Ex: Ramesh ko 500 diye")),
              actions: [
                TextButton(
                    onPressed: () {
                      if (c.text.isNotEmpty)
                        setState(() => hisaabList.add(c.text));
                      Navigator.pop(context);
                    },
                    child: Text("Save"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: Text("Namaste ${widget.callName} Ji"), centerTitle: true),
      body: Column(
        children: [
          if (status.isNotEmpty)
            Padding(
                padding: EdgeInsets.all(15),
                child: Text(status,
                    style: TextStyle(color: Colors.grey, fontSize: 18))),
          Expanded(
              child: hisaabList.isEmpty
                  ? Center(
                      child: Text("Abhi koi hisaab nahi",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: hisaabList.length,
                      itemBuilder: (_, i) => ListTile(
                          title: Text(hisaabList[i],
                              style: TextStyle(color: Colors.white)),
                          leading:
                              Icon(Icons.check_circle, color: Colors.green)))),
          // NICHE 3 ICON
          Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: manualAdd,
                    icon: Icon(Icons.edit, size: 32, color: Colors.white),
                    tooltip: "Haath se likho"),
                GestureDetector(
                    onTap: startListening,
                    child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.mic, size: 35, color: Colors.black))),
                IconButton(
                    onPressed: sendWhatsApp,
                    icon: Icon(Icons.send, size: 32, color: Colors.greenAccent),
                    tooltip: "WhatsApp bhejo"),
              ],
            ),
          )
        ],
      ),
    );
  }
}
