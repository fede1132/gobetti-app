import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orario_gobetti/services/online.dart';
import 'package:orario_gobetti/services/scraper.dart';
import 'package:orario_gobetti/pages/settings.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {

  WebViewController _controller;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var htmlData;
    if (_online = await OnlineChecker.isOnline()) {
      htmlData = await Scraper().getOrario((prefs.containsKey("OrarioGobettiOrarioTipo") ? (prefs.getString("OrarioGobettiOrarioTipo") == 'Classe' ? 'Classi' : (prefs.getString("OrarioGobettiOrarioTipo") == 'Docente' ? 'Docenti' : 'Aule')) : "Classi"), (prefs.containsKey("OrarioGobettiOrarioValore") ? prefs.getString("OrarioGobettiOrarioValore") : Scraper.scraped["classi"].first));
    }
    if (this.mounted) {
      setState(() {
        if (htmlData==null) _setHtml(prefs.getString("OrarioGobettiContent"));
        else _setHtml(htmlData);
      });
    }
  }

  _setHtml(html) {
    _controller.loadUrl(Uri.dataFromString(html, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.settings), onPressed: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Settings()))),
          if (!_online)
            Builder(builder: (BuildContext context) {
              return IconButton(
                  icon: Icon(Icons.signal_wifi_off),
                  color: Colors.redAccent,
                  onPressed: () {
                    Scaffold.of(context).showSnackBar(SnackBar(content: Text("Nessun accesso a internet!")));
                  }
              );
            })
        ],
      ),
      body: Center(
        child: WebView(
          initialUrl: "about:blank",
          onWebViewCreated: (WebViewController webViewController) async {
            _controller = webViewController;
            _setHtml("<h1>Caricamento in corso...</h1>");
            await _loadSettings();
          },
          navigationDelegate: (NavigationRequest request) {
            return NavigationDecision.prevent;
          },
        )
      )
    );
  }

}

