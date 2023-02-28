import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as cnv;

class ParkingLocation extends StatefulWidget {
  Map? data;
  double latitude;
  double longitude;
  String token;
  ParkingLocation(this.data, this.latitude, this.longitude, this.token);
  @override
  _ParkingLocationState createState() => _ParkingLocationState();
}

class _ParkingLocationState extends State<ParkingLocation>
    with TickerProviderStateMixin {
  OverlayState? overlayState;
  AnimationController? _animationController;
  Animation<double>? _animation;
  String TomTomApiKey = '';
  late Future _getRoute;
  List<LatLng> pointsList = [];
  double lati = 0;
  int newParkingClicked = 0;

  @override
  void initState() {
    overlayState = Overlay.of(context);
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation = Tween<double>(begin: 0.1, end: 2.2).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn));
    super.initState();
    print(widget.data);
    _determinePosition();
    _getRoute = getRoute();
  }

  Set<Marker> markers = {};
  Position? _currentPosition;

  ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  void _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      if (position != null) _currentPosition = position;
    });
  }

  void _showOverlay(BuildContext context) async {
    // Declaring and Initializing OverlayState
    // and OverlayEntry objects
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(builder: (context) {
      // You can return any widget you like
      // here to be displayed on the Overlay
      return Scaffold(
          backgroundColor: Colors.grey.withOpacity(0.45),
          body: Center(
              child: ScaleTransition(
                  scale: _animation!,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.done),
                    onPressed: () {
                      setState(() {});
                    },
                  ))));
      ;
    });

    // Inserting the OverlayEntry into the Overlay
    overlayState?.insert(overlayEntry);

    // Awaiting for 3 seconds
    await Future.delayed(Duration(seconds: 3));

    // Removing the OverlayEntry from the Overlay
    overlayEntry.remove();
    _animationController!.reset();
  }

  Future getRoute() async {
    var response = await http.get(Uri.parse(
        'https://api.tomtom.com/routing/1/calculateRoute/${widget.latitude.toString()},${widget.longitude.toString()}:${widget.data!["lat"]},${widget.data?["long"]}/json?travelMode=car&computeBestOrder=true&routeType=shortest&sectionType=travelMode&key=$TomTomApiKey'));
    var data = "[" + response.body + "]";
    var datajson =
        cnv.jsonDecode(response.body)["routes"][0]["legs"][0]["points"];
    for (var i = 0; i < datajson.length; i++) {
      pointsList.add(LatLng(datajson[i]["latitude"], datajson[i]["longitude"]));
    }
  }

  postParked() async {
    print(
        "uid: " + widget.data!["user_id"] + "\nclaimedby_id: " + widget.token);
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/parked.php"),
          body: {"uid": widget.data!["user_id"], "claimedby_id": widget.token});
    } catch (e) {
      print(e);
    }
  }

  postNewParking(int clicked) async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/new_parking.php"),
          body: {
            "lat": widget.data!["lat"].toString(),
            "long": widget.data!["long"].toString(),
            "uid": widget.token, //widget.data!["user_id"]
            "time": widget.data!["time"].toString()
          });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getRoute,
        builder: (context, snapshot) {
          // Future done with no errors
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return WillPopScope(
                onWillPop: () async {
                  if (isDialOpen.value) {
                    isDialOpen.value = false;

                    return false;
                  } else {
                    return true;
                  }
                },
                child: Scaffold(
                  floatingActionButton: SpeedDial(
                    animatedIcon: AnimatedIcons.menu_close,
                    openCloseDial: isDialOpen,
                    backgroundColor: Colors.blueAccent,
                    overlayColor: Colors.grey,
                    overlayOpacity: 0.5,
                    spacing: 15,
                    spaceBetweenChildren: 15,
                    closeManually: true,
                    children: [
                      SpeedDialChild(
                          child: Icon(Icons.sync),
                          label: 'New parking',
                          onTap: () {
                            newParkingClicked++;
                            postNewParking(newParkingClicked);
                            isDialOpen.value = false;
                            Navigator.pop(context, 'close');
                          }),
                      SpeedDialChild(
                          child: Icon(Icons.done),
                          label: 'Parked',
                          onTap: () {
                            postParked();
                            _showOverlay(context);
                            _animationController!.forward();
                            isDialOpen.value = false;
                            Navigator.pop(context, 'close');
                          }),
                    ],
                  ),
                  body: Center(
                    child: Container(
                      child: Column(
                        children: [
                          Flexible(
                              child: FlutterMap(
                            options: MapOptions(
                                center: LatLng(
                                    double.parse(widget.data?["lat"]),
                                    double.parse(widget.data?["long"])),
                                zoom: 16),
                            layers: [
                              TileLayerOptions(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayerOptions(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(
                                        double.parse(widget.data?["lat"]),
                                        double.parse(widget.data?["long"])),
                                    builder: (ctx) =>
                                        Icon(Icons.pin_drop, color: Colors.red),
                                  ),
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(lati, widget.longitude),
                                    builder: (ctx) =>
                                        Icon(Icons.pin_drop, color: Colors.red),
                                  ),
                                ],
                              ),
                              PolylineLayerOptions(
                                polylineCulling: false,
                                polylines: [
                                  Polyline(
                                    strokeWidth: 3.0,
                                    points: pointsList,
                                    color: Colors.blue,
                                  ),
                                ],
                              )
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                ));
          }

          // Future with some errors
          else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError)
            return Text("The error ${snapshot.error} occured");

          // Future not done yet
          else {
            //print(snapshot.connectionState);
            return Scaffold(
              body: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: MediaQuery.of(context).size.width / 1.5,
                  child: CircularProgressIndicator(strokeWidth: 10),
                ),
              ),
            );
          }
        });
  }
}
