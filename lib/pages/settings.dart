import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orario_gobetti/pages/home.dart';
import 'package:orario_gobetti/services/scraper.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _Settings createState() => _Settings();
}

class _Settings extends State<Settings> {

  String _dropdownTypeValue;
  List<DropdownMenuItem<String>> _dropdownTypeValueValues;
  String _dropdownValueValue;

  SharedPreferences prefs;
  TextEditingController txt;

  @override
  initState({Key key}) {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    txt = TextEditingController(text: (prefs.containsKey("OrarioGobettiURL") ? prefs.getString("OrarioGobettiURL") : "http://www.istitutogobetti.it/2020/index.php"));
    setState(() {
      _dropdownTypeValue = prefs.containsKey("OrarioGobettiOrarioTipo") ? prefs.getString("OrarioGobettiOrarioTipo") : "Classe";
      loadValues();
      _dropdownValueValue = prefs.containsKey("OrarioGobettiOrarioValore") ? prefs.getString("OrarioGobettiOrarioValore") : _dropdownTypeValueValues.first.value;
    });
  }

  loadValues() {
    setState(() {
      _dropdownTypeValueValues = Scraper.scraped[_dropdownTypeValue == 'Classe' ? 'classi' : (_dropdownTypeValue == 'Docente' ? 'docenti' : 'aule')]
          .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value));
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Row(
          children: [
            IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
            }),
            Text("Impostazioni")
          ],
        )),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Text("Seleziona tipo orario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton(value: _dropdownTypeValue, items: <String>['Classe', 'Docente', 'Aula']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(), onChanged: (e) {
                    prefs.setString("OrarioGobettiOrarioTipo", e);
                    setState(() {
                      _dropdownTypeValue = e;
                      loadValues();
                      _dropdownValueValue = _dropdownTypeValueValues.first.value;
                      prefs.setString("OrarioGobettiOrarioValore", _dropdownTypeValueValues.first.value);
                    });
                  }),
                  SizedBox(width: 10),
                  DropdownButton(value: _dropdownValueValue, items: _dropdownTypeValueValues, onChanged: (e) {
                    prefs.setString("OrarioGobettiOrarioValore", e);
                    setState(() {
                      _dropdownValueValue = e;
                    });
                  }),
                ],
              ),
              Divider(),
              Text("Forza aggiornamento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Forza l'aggiornamento dell'orario"),
              Builder(builder: (context) {
                return FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    padding: EdgeInsets.all(8.0),
                    splashColor: Colors.blueAccent,
                    onPressed: () {
                      Future(() async{
                        await Scraper().getOrario((prefs.containsKey("OrarioGobettiOrarioTipo") ? (prefs.getString("OrarioGobettiOrarioTipo") == 'Classe' ? 'Classi' : (prefs.getString("OrarioGobettiOrarioTipo") == 'Docente' ? 'Docenti' : 'Aule')) : "Classi"), (prefs.containsKey("OrarioGobettiOrarioValore") ? prefs.getString("OrarioGobettiOrarioValore") : Scraper.scraped["classi"].first));
                      }).then((value) => Scaffold.of(context).showSnackBar(SnackBar(content: Text("Orario ricaricato!"))));
                    },
                    child: Text('AGGIORNA')
                );
              }),
              Spacer(),
              Text("Made with ❤ by Federico Gualandri"),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  text: "Codice sorgente disponibile su GitHub",
                  recognizer: TapGestureRecognizer()..onTap = () async => await launch("https://github.com/fede1132/gobetti-app/")
                ),
              )
            ],
          ),
        )
    );
  }
}