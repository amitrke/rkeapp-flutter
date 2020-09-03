import 'package:RkeApp/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String _name;
    final rkeUser = Provider.of<RkeUser>(context); // gets the firebase user
    final albumData = Provider.of<AlbumData>(context);

    if (rkeUser != null) {
      _name = rkeUser.name;
    } else {
      _name = "";
    }

    List<Widget> list = [ListTile()];

    if (albumData != null) {
      print(albumData);
      albumData.images.forEach((image) {
        list.add(ListTile(title: Text(image.path)));
      });
    }

    return Scaffold(
      body: ListView(children: list),
    );
  }
}
