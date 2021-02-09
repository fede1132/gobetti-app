import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:http/http.dart' as http;
import 'online.dart' as OnlineChecker;

class Scraper {

  static String URL;
  static var scraped;

  loadURL() async {
    var response = await http.get('https://api.github.com/gists/076efba5988869351cc295f6ac566c65');
    if (response.statusCode != 200) return;
    var data = json.decode(response.body);
    Scraper.URL = data['files']['url.txt']['content'];
  }

  getValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var scraped = {"classi": <String>[], "docenti": <String>[], "aule": <String>[]};
    if (!await OnlineChecker.OnlineChecker.isOnline()) {
      if (prefs.containsKey("OrarioGobettiClassi")) {
        scraped["classi"] = prefs.getStringList("OrarioGobettiClassi");
        scraped["docenti"] = prefs.getStringList("OrarioGobettiDocenti");
        scraped["aule"] = prefs.getStringList("OrarioGobettiAule");
        return scraped;
      } else {
        return scraped;
      }
    }
    if (URL==null) await loadURL();
    var path = URL.split(RegExp('(http:).*\.(it|com|edu|net|org)'))[1];
    final scraper = WebScraper(URL.replaceAll(path, ''));
    if (await scraper.loadWebPage(path)) {
      List<Map<String, dynamic>> elements = scraper.getElement('body > center > table > tbody > tr > td > p > a', ['href']);
      elements.forEach((element) {
        var title = element.values.first;
        String href = element.values.last.values.first;
        scraped[(href.contains("Classi/") ? "classi" : (href.contains("Docenti/") ? "docenti" : "aule"))].add(title);
      });
    }
    Scraper.scraped = scraped;
    prefs.setStringList("OrarioGobettiClassi", scraped["classi"]);
    prefs.setStringList("OrarioGobettiDocenti", scraped["docenti"]);
    prefs.setStringList("OrarioGobettiAule", scraped["aule"]);
    return scraped;
  }

  getOrario(type, value) async {
    if (URL==null) await loadURL();
    var url = URL.replaceAll('index.html', '');
    var response = await http.get('$url$type/$value.html');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (response.statusCode != 200) {
      prefs.setString("OrarioGobettiContent", '<h1 style="color: red;">Impossibile trovare una pagina al link: $url$type/$value.html</h1>');
      return '<h1 style="color: red;">Impossibile trovare una pagina al link: $url$type/$value.html</h1>';
    }
    String body = response.body.replaceAll(new RegExp('href=(["\'])(.*?)\1'), '');
    prefs.setString("OrarioGobettiContent", body);
    return body;
  }
}