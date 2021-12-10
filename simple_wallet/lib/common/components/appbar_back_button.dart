import 'package:flutter/material.dart';

class AppBarBackButton extends StatelessWidget {
  AppBarBackButton({this.onBack, this.color});

  Function onBack;
  Color color;
  //final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onBack(),
      child: Center(
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
