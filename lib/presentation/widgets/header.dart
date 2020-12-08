import 'package:flutter/material.dart';
import 'package:mucke/presentation/theming.dart';

class Header extends StatelessWidget {
  const Header({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Text('Home', style: TEXT_HEADER),
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: null,
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}
