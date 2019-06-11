import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'customize_expansion_tile.dart';

class Detail extends StatefulWidget {

  final id;

  Detail(this.id);

  @override
  State<StatefulWidget> createState() {
    return DetailState(id);
  }
}

class DetailState extends State<Detail> {
  final id;

  DetailState(this.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('详情'),),
      body: Center(
        child: FutureBuilder<DetailModel>(
          future: fetchPost(id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                alignment: Alignment(0, 0),
                children: <Widget>[
                  WebView(onWebViewCreated: (WebViewController controller) {
                    String img = "<script type='text/javascript'>window.onload = function(){let a = document.getElementsByClassName('img-place-holder'); if (a.length == 1) {a[0].style.backgroundImage='url(${snapshot.data.image})';a[0].style.backgroundRepeat = \"no-repeat\"; a[0].style.backgroundSize = \"cover\";a[0].style.backgroundPosition=\"center\"}}</script>";
                    String s = img + snapshot.data.body + '<link type="text/css" rel="stylesheet" href="${snapshot.data.css[0]}"></link>';
                    final String contentBase64 = base64Encode(const Utf8Encoder().convert(s));
                    controller.loadUrl('data:text/html;base64,$contentBase64');
                  }, javascriptMode: JavascriptMode.unrestricted,)
                ],
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

}

Future<DetailModel> fetchPost(id) async{
  Dio dio = Dio();
  final Response response = await dio.get("https://news-at.zhihu.com/api/4/news/${id}");
  return DetailModel.fromJson(response.data);
}

class DetailModel {
  final String body;
  final String image_source;
  final String title;
  final String image;
  final String share_url;
  final List<String> css;
  final List<String> images;


  DetailModel(this.body, this.image_source, this.title, this.image,
      this.share_url, this.css, this.images);

  DetailModel.fromJson(Map<String, dynamic> json):
        body = json['body'],
        image_source = json['image_source'],
        title = json['title'],
        image = json['image'],
        share_url = json['share_url'],
        css = List<String>.from(json['css']),
        images = List<String>.from(json['images']);
}