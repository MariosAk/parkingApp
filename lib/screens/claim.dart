import 'package:flutter/material.dart';
import 'package:pasthelwparking_v1/screens/parking_location.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ClaimPage extends StatefulWidget {
  Map? data;
  String token;
  double latitude, longitude;
  ClaimPage(this.data, this.token, this.latitude, this.longitude);
  @override
  _ClaimPageState createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  OverlayState? overlayState;

  @override
  void initState() {
    super.initState();
    overlayState = Overlay.of(context);

    //_determinePosition();
    //registerNotification();
  }

//call delete_time.php to delete an entry from
//notificationTimeTrack table based on $token
  postDeleteTime() async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/delete_time.php"),
          body: {"uid": widget.token});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  postClaim() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/claim.php"),
          body: {"uid": widget.data!["user_id"], "claimedby_id": widget.token});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    //OverlayEntry? overlayEntry;
    //overlayEntry = OverlayEntry(builder: (context) {
    // to be displayed on the Overlay
    return Scaffold(
        backgroundColor: Colors.grey.withOpacity(0.45),
        body: Center(
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.all(Radius.circular(40))),
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    //Image.asset('Assets/Images/SUV.png'),

                    if (widget.data!["cartype"] == "Sedan")
                      Image.asset('Assets/Images/Sedan.png')
                    else if (widget.data!["cartype"] == "Coupe")
                      Image.asset('Assets/Images/Coupe.png')
                    else if (widget.data!["cartype"] == "Pickup")
                      Image.asset('Assets/Images/Pickup.png')
                    else if (widget.data!["cartype"] == "Jeep")
                      Image.asset('Assets/Images/Jeep.png')
                    else if (widget.data!["cartype"] == "Wagon")
                      Image.asset('Assets/Images/Wagon.png')
                    else if (widget.data!["cartype"] == "Crossover")
                      Image.asset('Assets/Images/Crossover.png')
                    else if (widget.data!["cartype"] == "Hatchback")
                      Image.asset('Assets/Images/Hatchback.png')
                    else if (widget.data!["cartype"] == "Van")
                      Image.asset('Assets/Images/Van.png')
                    else if (widget.data!["cartype"] == "Sportcoupe")
                      Image.asset('Assets/Images/Sportcoupe.png')
                    else if (widget.data!["cartype"] == "SUV")
                      Image.asset('Assets/Images/SUV.png')
                    else
                      Image.asset('Assets/Images/Sedan.png'),
                    Text("A parking spot is free for you to claim!",
                        style: GoogleFonts.openSans(
                            textStyle: TextStyle(color: Colors.black),
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    TextButton(
                      child: Text("Claim",
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.w600,
                          )),
                      onPressed: () {
                        postClaim();
                        Navigator.pop(context, 'close');
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ParkingLocation(
                                widget.data,
                                widget.latitude,
                                widget.longitude,
                                widget.token)));
                      },
                    ),
                    TextButton(
                      child: Text("Check later",
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.w600,
                          )),
                      onPressed: () {
                        Navigator.pop(context, 'close');
                        setState(() {});
                      },
                    ),
                    TextButton(
                      child: Text("Cancel",
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.w600,
                          )),
                      onPressed: () {
                        Navigator.pop(context, 'close');
                        setState(() {});
                      },
                    ),
                  ],
                ))));
  }
}
