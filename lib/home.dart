import 'package:RkeApp/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String _name;
    final rkeUser = Provider.of<RkeUser>(context); // gets the firebase user
    if (rkeUser != null){
      _name = rkeUser.name;
    } else {
      _name = "";
    }
    return Scaffold(
      body: Center(child: Text('$_name You have pressed the button times.')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
