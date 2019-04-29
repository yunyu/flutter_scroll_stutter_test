import 'package:flutter/material.dart';
import 'dart:math';

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
  final scrollPosNotifier = ValueNotifier<double>(0.0);

  ImageProvider _getRandomImage(int index) {
    final imageId = (index + 50) % 1000; // Skip the first 50 images
    return NetworkImage("https://picsum.photos/id/$imageId/540/960");
  }

  String _genRandomText({int seed, int numWords}) {
    final random = Random(seed);
    return Iterable.generate(
            numWords,
            (_) => String.fromCharCodes(Iterable.generate(3 + random.nextInt(5),
                (_) => (random.nextBool() ? 65 : 97) + random.nextInt(26))))
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final windowPadding = MediaQuery.of(context).padding;
    return LayoutBuilder(builder: (ctx, constraints) {
      // Workaround for https://github.com/flutter/flutter/issues/25827
      if (constraints.maxHeight == 0) {
        return Container();
      }
      final itemExtent = (constraints.maxHeight - windowPadding.top) * 0.85;
      return NotificationListener<ScrollUpdateNotification>(
          child: ListView.builder(
            padding: windowPadding,
            itemExtent: itemExtent,
            itemBuilder: (ctx, index) => FeedItem(
                  image: _getRandomImage(index),
                  title: _genRandomText(seed: index, numWords: 2),
                  description: _genRandomText(seed: index, numWords: 10),
                  scrollPosNotifier: scrollPosNotifier,
                  visibilityResolver: ItemVisibilityResolver(
                      itemExtent: itemExtent, index: index),
                ),
          ),
          onNotification: (notif) {
            scrollPosNotifier.value = notif.metrics.pixels;
            return true;
          });
    });
  }
}

// Parallax calculation adapted from
// https://iirokrankka.com/2017/09/23/bringing-the-pagetransformer-from-android-to-flutter/
class ItemVisibilityResolver {
  final double itemExtent;
  final int index;

  ItemVisibilityResolver({@required this.itemExtent, @required this.index});

  // Returns a value from -1 to 1, depending on the scroll position
  double resolveVisibility(double scrollPosition) {
    final basePos = itemExtent * index;
    return ((basePos - scrollPosition) / itemExtent).clamp(-1.0, 1.0);
  }
}

class FeedItem extends StatelessWidget {
  final ImageProvider image;
  final String title;
  final String description;
  final ValueNotifier<double> scrollPosNotifier;
  final ItemVisibilityResolver visibilityResolver;

  FeedItem(
      {@required this.image,
      @required this.title,
      @required this.description,
      @required this.scrollPosNotifier,
      @required this.visibilityResolver});

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
              ParallaxImage(
                  image: image,
                  scrollPosNotifier: scrollPosNotifier,
                  visibilityResolver: visibilityResolver),
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

class ParallaxImage extends StatelessWidget {
  final ImageProvider image;
  final ValueNotifier<double> scrollPosNotifier;
  final ItemVisibilityResolver visibilityResolver;

  static const PARALLAX_EXTENT = 75.0;

  ParallaxImage(
      {@required this.image,
      @required this.scrollPosNotifier,
      @required this.visibilityResolver});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth + 2; // Add 1px strip on both sides
      final height = constraints.maxHeight + 2 * PARALLAX_EXTENT;
      return RepaintBoundary(
          child: AnimatedBuilder(
              animation: scrollPosNotifier,
              child: RepaintBoundary(
                  child: OverflowBox(
                      minWidth: width,
                      minHeight: height,
                      maxHeight: height,
                      maxWidth: width,
                      child: Image(
                        image: image,
                        fit: BoxFit.cover,
                      ))),
              builder: (ctx, child) => Transform.translate(
                  offset: Offset(
                      0.0,
                      -visibilityResolver
                              .resolveVisibility(scrollPosNotifier.value) *
                          PARALLAX_EXTENT),
                  child: child)));
    });
  }
}
