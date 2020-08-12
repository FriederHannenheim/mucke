import 'package:flutter/material.dart';

class QueueCard extends StatefulWidget {
  const QueueCard({Key key, this.boxConstraints}) : super(key: key);

  final BoxConstraints boxConstraints;

  @override
  _QueueCardState createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  final title = 'Fire';
  final artist = 'Beartooth';
  final height = 64.0;

  bool _first = true;
  double _currentHeight;

  @override
  void initState() {
    _currentHeight = height;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: _currentHeight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _currentHeight =
                  _first ? widget.boxConstraints.maxHeight : height;
              _first = !_first;
            });
          },
          child: Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: <Widget>[
                      const Icon(Icons.expand_less),
                      Container(
                        width: 4.0,
                      ),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(text: '$title'),
                            const TextSpan(text: ' • ', style: TextStyle(color: Colors.white70)),
                            TextSpan(text: '$artist', style: const TextStyle(fontWeight: FontWeight.w300, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
    );
  }
}
