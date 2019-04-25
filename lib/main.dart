import 'package:flutter/material.dart';
import 'package:random_words/random_words.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scroll Stutter Test',
      home: Scaffold(body: FeedView()),
    );
  }
}

class FeedView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FeedViewState();
  }
}

class _FeedViewState extends State<FeedView> {
  ImageProvider _getRandomImage(int index) {
    final imageId = (index + 50) % 1000; // The first 50 images are kinda same-y
    return NetworkImage("https://picsum.photos/id/$imageId/540/960");
  }

  String _genTitle() {
    return generateWordPairs().first.asPascalCase;
  }

  String _genDescription() {
    return generateAdjective().take(10).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final windowPadding = MediaQuery.of(context).padding;
    return LayoutBuilder(builder: (ctx, constraints) {
      // Workaround for https://github.com/flutter/flutter/issues/25827
      if (constraints.maxHeight == 0) {
        return Container();
      }
      return ListView.builder(
        padding: windowPadding,
        itemExtent: (constraints.maxHeight - windowPadding.top) * 0.85,
        itemBuilder: (ctx, index) => FeedItem(
              image: _getRandomImage(index),
              title: _genTitle(),
              description: _genDescription(),
            ),
      );
    });
  }
}

class FeedItem extends StatelessWidget {
  final ImageProvider image;
  final String title;
  final String description;

  FeedItem(
      {@required this.image, @required this.title, @required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 18.0, right: 18.0, top: 18.0, bottom: 0),
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(0x35), blurRadius: 9.0)
        ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(9.0),
            child: Stack(children: [
              Image(
                image: image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(0x80)
                      ])),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .display1
                                .apply(color: Colors.white)),
                        SizedBox(height: 9.0),
                        Text(description,
                            style: Theme.of(context)
                                .textTheme
                                .body1
                                .apply(color: Colors.white))
                      ]))
            ])));
  }
}
