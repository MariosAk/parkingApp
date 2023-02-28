import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pasthelwparking_v1/main.dart';
import 'package:pasthelwparking_v1/globals.dart';

class EnableLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          Container(
              color: Color.fromRGBO(246, 255, 255, 1.0),
              child: SafeArea(
                  child: CircleAvatar(
                backgroundColor: Color.fromRGBO(246, 255, 255, 1.0),
                radius: 100,
                child: Image.asset('Assets/Images/location.gif'),
              ))),
          Text(
            "Please enable location services.",
            style: GoogleFonts.openSans(
                textStyle: TextStyle(color: Colors.black),
                fontWeight: FontWeight.w600,
                fontSize: 20),
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              onPrimary: Colors.white,
              shadowColor: Colors.grey,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0)),
            ),
            onPressed: () {
              Geolocator.openLocationSettings();
            },
            child: Text(
              'Settings',
              style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          )
        ])));
  }
}
