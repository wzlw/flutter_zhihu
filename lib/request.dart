import 'package:dio/dio.dart';

class request extends BaseOptions {
  @override
  void set baseUrl(String _baseUrl) {
    super.baseUrl = 'https://news-at.zhihu.com/api/4/';
  }
}