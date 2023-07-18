import 'dart:convert';

import '../library/http/http.dart';

class Hitokito {
  String hitokoto = '';
  String type = '';
  String from = '';

  Hitokito.fromJson(Map<String, dynamic> json) {
    hitokoto = json['hitokoto'];
    type = json['type'];
    from = json['from'];
  }

  Hitokito();
}

Future<String> apiRandomImage() async {
  final response = await Http.client
      .get(Uri.parse('https://random-picture.vercel.app/api/?json'));
  final json = Map<String, dynamic>.from(jsonDecode(response.body));
  final url = json['url'].toString();
  return url;
}

Future<Hitokito> apiHitokito() async {
  final response =
      await Http.client.get(Uri.parse('https://v1.hitokoto.cn/?c=a&c=b'));
  return Hitokito.fromJson(jsonDecode(response.body));
}
