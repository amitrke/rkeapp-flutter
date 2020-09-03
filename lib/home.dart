import 'package:RkeApp/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final albumData = Provider.of<AlbumData>(context);

    List<Widget> list = [];

    if (albumData != null) {
      print(albumData);
      for (final img in albumData.images) {
        list.add(Image.network(
          img.url,
          height: 240.0,
        ));
      }
    }

    return Scaffold(
      body: ListView(children: list),
    );
  }
}
