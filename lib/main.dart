import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'detail.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'customize_expansion_tile.dart';

void main() => {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(MyApp());
  })
};

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '首页'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _current = 0;
  ScrollController _controller = ScrollController();
  List<BaseModel> _list = [];
  bool isLoadding = false;

  @override
  void initState() {
    fetchPost();
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _list.length == 0 ? CircularProgressIndicator() :
        RefreshIndicator(
          onRefresh: () {
            return fetchPost();
          },
          child: _buildListView(),
        )
      ),
    );
  }

  FutureBuilder<List<BaseModel>> buildFutureBuilder() {
     return FutureBuilder<List<BaseModel>>(
//        future: fetchPost(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
              onRefresh: () {
                print('refresh');
                return;
              },
              child: _buildListView(),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        }
    );
  }

  ListView _buildListView() {
    return ListView.builder(
        controller: _controller,
        itemCount: _list.length + 2,
        itemBuilder: (context, index) {
            if (index == 0) {
              Post post = _list[index] as Post;
              return header(post.topStories);
            }
            int tIndex = index - 1;
            if (index == _list.length + 1) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Center(
                  child: new Opacity(
                    opacity: isLoadding ? 1.0 : 0.0,
                    child: new CircularProgressIndicator(),
                  ),
                ),
              );
            }
            var time = DateTime.parse(_list[tIndex].date);
            var now = DateTime.now();
            bool isToday = false;
            if (time.year == now.year && time.month == now.month && time.day == now.day) {
              isToday = true;
            }
            var week = {7: '日', 1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六',};
            return CustomizeExpansionTile(
              title: Text(isToday ? '今日热闻' : '${time.month}月${time.day}日 星期${week[time.weekday]}', style: TextStyle(fontSize: 16.0, color: Colors.black45),),
              initiallyExpanded: true,
              children: map<Widget>(_list[tIndex].stories, (i, item) {
                return Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.fromLTRB(5.0,10.0,5.0,10.0),
                    title: Text("${_list[tIndex].stories[i].title}"),
                    trailing: Image.network("${_list[tIndex].stories[i].images[0]}", width: 80.0, height: 60.0, alignment: Alignment.centerRight, fit: BoxFit.cover,),
                    onTap: () {
                      skipDetail(_list[tIndex].stories[i].id);
                    },
                  ),
                );
              }),
            );
        });
  }

  Future<List<BaseModel>> fetchPost() async {
    _list.clear();
    Dio dio = new Dio();
    final Response response = await dio.get('https://news-at.zhihu.com/api/4/news/latest');
    Post post = Post.fromJson(response.data);
    List<BaseModel> list = List();
    list.add(post);
    var now = DateTime.now();
    String date = '${now.year}${now.month > 10 ? now.month : '0' + now.month.toString()}${now.day}';
    final Response beforeResponse = await dio.get('https://news-at.zhihu.com/api/4/news/before/${date}');
    list.add(BaseModel.fromJson(beforeResponse.data));
    setState(() {
      _list.addAll(list);
    });
    return list;
  }

   _loadMore() async {
    if (isLoadding) {
      return;
    }
    setState(() {
      isLoadding = true;
    });
    Dio dio = new Dio();
    var now = DateTime.now();
    int month = now.month;
    int day = now.day;
    day -= (_list.length - 1);
    if (day == 0) {
      month = month - 1;
      day = getLen(now.year, month);
    } else if (day < 0) {
      month -= 1;
      day += getLen(now.year, month);
    }
    String date = "${now.year}${month > 10 ? month : '0' + month.toString()}${day >= 10 ? day : '0' + day.toString()}";
    try {
      String url = 'https://news-at.zhihu.com/api/4/news/before/' + date;
      final Response beforeResponse = await dio.get(url);
      setState(() {
        _list.add(BaseModel.fromJson(beforeResponse.data));
        isLoadding = false;
      });
    } catch (er){
    }
  }

  // 判断是否是润年
  bool isLeap(int year) {
    if (year % 4 == 0 && year % 100 > 0) {
      return true;
    } else if (year % 400 == 0 && year % 3200 > 0) {
      return true;
    } else {
      return false;
    }
  }

  // 获取月份最大日期
  int getLen(int year, int month) {
    if (month == 2) {
      if (isLeap(year)) {
        return 29;
      } else {
        return 28;
      }
    } else {
      if (month < 8) {
        if (month % 2 > 0) {
          return 31;
        } else {
          return 30;
        }
      } else {
        if (month % 2 > 0) {
          return 30;
        } else {
          return 31;
        }
      }
    }
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for(var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }

  void skipDetail(int id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Detail(id);
    }));
  }

  Widget header(List<TopItem> topStories) {
      List<TopItem> list = topStories;
      return Stack(
        children: <Widget>[
          CarouselSlider(
            height: 200.0,
            viewportFraction: 1.0,
            autoPlay: true,
            items: list.map((i) {
              return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        skipDetail(i.id);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Image.network(i.image, fit: BoxFit.cover,),
                      ),
                    );
                  }
              );
            }).toList(),
            onPageChanged: (index) {
              setState(() {
                _current = index;
              });
            },
            pauseAutoPlayOnTouch: Duration(seconds: 2),
          ),
          Positioned(
              bottom: 0,left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(top: 5.0),
                color: Color.fromRGBO(0, 0, 0, 0.4),
                child: Column(children: <Widget>[
                  Text(list[_current].title, style: TextStyle(color: Colors.white,fontSize: 17.0),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: map<Widget>(list, (index, url) {
                      return Container(
                        width: 8.0, height: 8.0, margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.0),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: index != _current ? Color.fromRGBO(181, 181, 181, 0.9) : Colors.white),
                      );
                    }),
                  )
                ],),
              )
          )
        ],
      );
    }
}

class BaseModel {
  final String date;
  final List<Item> stories;

  BaseModel(this.date, this.stories);

  BaseModel.fromJson(Map<String, dynamic> json):date = json['date'],
        stories = (json['stories'] as List).map((i) => Item.fromJson(i)).toList();

}

class Post extends BaseModel {
  final List<TopItem> topStories;


  Post(String date, List<Item> stories, this.topStories):super(date, stories);

  Post.fromJson(Map<String, dynamic> json):
        topStories = (json['top_stories'] as List).map((j) => TopItem.fromJson(j)).toList(), super.fromJson(json);
}

class Item {
  final String title;
  final String ga_prefix;
  final bool multipic;
  final int type;
  final int id;
  final List<String> images;

  Item(this.title, this.ga_prefix, this.multipic, this.type, this.id,
      this.images);

  Item.fromJson(Map<String, dynamic> json) : title = json['title'],
        ga_prefix = json['ga_prefix'],
        multipic = json['multipic'],
        type = json['type'],
        id = json['id'],
        images = List<String>.from(json['images']);

}


class TopItem {
  final String image;
  final int type;
  final int id;
  final String ga_prefix;
  final String title;

  TopItem(this.image, this.type, this.id, this.ga_prefix, this.title);

  TopItem.fromJson(Map<String, dynamic> json):image = json['image'],
        type = json['type'],
        id = json['id'],
        ga_prefix = json['ga_prefix'],
        title = json['title'];
}