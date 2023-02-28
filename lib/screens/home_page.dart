import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pasthelwparking_v1/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:show_up_animation/show_up_animation.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert' as cnv;
import 'overlays/buttonOverlay.dart';
import 'overlays/buttonOverlayRight.dart';
import 'notifications_page.dart';
import 'package:badges/badges.dart';
import 'package:square_percent_indicater/square_percent_indicater.dart';
import 'package:pasthelwparking_v1/globals.dart' as globals;

class HomePage extends StatefulWidget {
  String? address, token;
  double latitude;
  double longitude;
  int notificationCount;
  HomePage(this.address, this.token, this.latitude, this.longitude,
      this.notificationCount);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final FirebaseMessaging _messaging;
  PushNotification? _notificationInfo, notification;
  String? token, address;
  DateTime? notifReceiveTime;
  Position? _currentPosition;
  double height = 100;

  double width = 100;

  int index = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  bool searching = false, leaving = false;

  bool _isLoading = false;

  bool isSelected = false;
  bool _searchingTextfield = false;
  double? containerHeight, containerWidth, x, y;

  double _spreadRadius = 7;
  AnimationController? _animationController;

  Animation<double>? _animation;

  String ApiKey = '';
  String TomTomApiKey = '';
  final _controller = TextEditingController();
  String searchTxt = "";
  String lat = "";
  String lon = "";
  MapController _mapctl = MapController();
  TextEditingController textController = TextEditingController();

  int value = 0;
  late Timer timer;

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _animation = Tween<double>(begin: 1.0, end: 2.2).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn));
    timer = Timer.periodic(Duration(milliseconds: 30), (Timer t) {
      setState(() {
        value = (value + 1) % 100;
      });
    });
    //_determinePosition();
    //registerNotification();
  }

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
      _currentPosition = position;
    });
  }

  cancelSearch() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"),
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/cancelSearch.php"),
          body: {
            "uid": widget.token,
          });
    } catch (e) {
      print(e);
    }
  }

  postData() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"),
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/searching.php"),
          body: {
            "lat": widget.latitude.toString(),
            "long": widget.longitude.toString(),
            "uid": widget.token,
          });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  postData2() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/leaving.php"),
          body: {
            "lat": widget.latitude.toString(),
            "long": widget.longitude.toString(),
            "uid": widget.token,
            "newParking": "false",
          });
    } catch (e) {
      print(e);
    }
  }

  updateData() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/updateCenter.php"),
          body: {
            "lat": widget.latitude.toString(),
            "long": widget.longitude.toString(),
            "uid": widget.token,
          });
    } catch (e) {
      print(e);
    }
  }

  useridExists(userid) async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/itExists.php"),
          body: {
            "user_id": userid,
          });
      var data = response.body;
      return data;
    } catch (e) {
      print(e);
    }
  }

  Future<List> getSelectionPosition(value) async {
    List<dynamic> locationList = [];
    var encstr = Uri.encodeComponent(value);
    var response = await http.get(Uri.parse(
        'https://api.tomtom.com/search/2/search/$encstr.json?key=$TomTomApiKey&language=el-GR&limit=1&countrySet=GR&idxSet=POI,PAD,Addr,Str'));
    var datajson = cnv.jsonDecode(response.body)["results"];
    for (var i = 0; i < datajson.length; i++) {
      var pair = {
        'lat': datajson[i]["position"]["lat"].toString(),
        'lon': datajson[i]["position"]["lon"].toString(),
      };
      locationList.add(pair);
    }
    return locationList;
  }

  Future<List> getAddress(value) async {
    List resultList = [];
    var encstr = Uri.encodeComponent(value);
    var response = await http.get(Uri.parse(
        'https://api.tomtom.com/search/2/search/$encstr.json?key=$TomTomApiKey&language=el-GR&limit=4&typeahead=true&countrySet=GR&idxSet=POI,PAD,Addr,Str'));
    var data = "[" + response.body + "]";
    var datajson = cnv.jsonDecode(response.body)["results"];
    for (var i = 0; i < datajson.length; i++) {
      /*var pair = {
        'address': datajson[i]["address"]["freeformAddress"].toString(),
        'lat': datajson[i]["position"]["lat"].toString(),
        'lon': datajson[i]["position"]["lon"].toString(),
      };*/
      resultList.add(datajson[i]["address"]["freeformAddress"].toString());
    }
    return resultList;
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Icon(
        Icons.home,
        size: 30,
        color: Colors.white,
      ),
      Icon(Icons.person, size: 30, color: Colors.white),
      Icon(Icons.notifications, size: 30, color: Colors.white),
      Icon(Icons.logout, size: 30, color: Colors.white),
    ];
    return Container(
        color: Color.fromRGBO(246, 255, 255, 1.0),
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                "Home",
                style: GoogleFonts.openSans(
                    textStyle: TextStyle(color: Colors.black)),
              ),
              leading: Badge(
                badgeContent: Text(
                  widget.notificationCount.toString(),
                  style: GoogleFonts.openSans(
                      textStyle: TextStyle(color: Colors.white)),
                ),
                toAnimate: true,
                position: BadgePosition.topEnd(top: -2, end: -2),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: Colors.black38,
                  ),
                  onPressed: () => {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => NotificationPage()))
                        .then((value) => setState(() {
                              widget.notificationCount = value;
                            })),
                    print("notifications")
                  },
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showGifSearching
                      ? Container(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 100,
                                child: Container(
                                  width: 260,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(100)),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          'https://i.giphy.com/media/fan5q5SIksKGWUzV5D/200.gif'),

                                      //width: 200,

                                      fit: BoxFit.cover,

                                      //),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  value: 1,
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE8B961),

                                  value:
                                      null, // Change this value to update the progress
                                ),
                              ),
                            ],
                          ),
                        )
                      : AnimatedContainer(
                          duration:
                              Duration(milliseconds: 2000), // Animation speed
                          child: SingleChildScrollView(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Hi, are you leaving or searching?",
                                  style: GoogleFonts.openSans(
                                      textStyle: TextStyle(color: Colors.black),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              if (_searchingTextfield)
                                ShowUpAnimation(
                                    delayStart: Duration(seconds: 0),
                                    animationDuration:
                                        Duration(milliseconds: 300),
                                    curve: Curves.bounceIn,
                                    direction: Direction.horizontal,
                                    offset: 0.5,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          left: 15.0, right: 15.0),
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TypeAheadField(
                                            textFieldConfiguration:
                                                TextFieldConfiguration(
                                              autofocus: true,
                                              controller: textController,
                                              style: GoogleFonts.openSans(
                                                  textStyle: TextStyle(
                                                      color: Colors.black),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                hintText: 'Enter address..',
                                                contentPadding:
                                                    const EdgeInsets.all(10),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: BorderSide(
                                                      color: Color.fromRGBO(
                                                          225, 235, 235, 1.0),
                                                      width: 2),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              20.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.blue),
                                                ),
                                              ),
                                            ),
                                            suggestionsCallback:
                                                (pattern) async {
                                              var data;

                                              if (pattern?.isEmpty ?? true) {
                                                data = await getAddress(" ");
                                                return data;
                                              }
                                              data = await getAddress(pattern);
                                              return data;
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                leading:
                                                    Icon(Icons.location_on),
                                                title:
                                                    Text(suggestion.toString()),
                                              );
                                            },
                                            onSuggestionSelected:
                                                (suggestion) async {
                                              if (suggestion == null) return;
                                              var position =
                                                  await getSelectionPosition(
                                                      suggestion);

                                              setState(() {
                                                lat = position[0]['lat'];
                                                lon = position[0]['lon'];

                                                widget.latitude =
                                                    double.parse(lat);
                                                widget.longitude =
                                                    double.parse(lon);
                                                textController.text =
                                                    suggestion.toString();
                                                widget.address =
                                                    suggestion.toString();
                                              });
                                              var latlng = LatLng(
                                                  double.parse(lat),
                                                  double.parse(lon));
                                              double zoom = 14.0;
                                              _mapctl.move(latlng, zoom);
                                              updateData();
                                            },
                                          )),
                                    )),
                              Container(
                                  margin: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(230, 241, 255, 1.0),
                                    border: Border.all(
                                        color:
                                            Color.fromRGBO(230, 241, 255, 1.0),
                                        width: 10.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  height:
                                      MediaQuery.of(context).size.height / 4,
                                  width: MediaQuery.of(context).size.width,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: FlutterMap(
                                        mapController: _mapctl,
                                        options: MapOptions(
                                            center: LatLng(widget.latitude,
                                                widget.longitude),
                                            zoom: 14),
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
                                                point: LatLng(widget.latitude,
                                                    widget.longitude),
                                                builder: (ctx) => Icon(
                                                  Icons.pin_drop,
                                                  color: Colors.deepOrange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          CircleLayerOptions(
                                            circles: [
                                              CircleMarker(
                                                  //radius marker
                                                  point: LatLng(widget.latitude,
                                                      widget.longitude),
                                                  color: Colors.blue
                                                      .withOpacity(0.3),
                                                  borderStrokeWidth: 3.0,
                                                  borderColor: Colors.blue,
                                                  radius: 100 //radius
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ))),
                              Container(
                                margin: EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  widget.address!,
                                  style: GoogleFonts.openSans(
                                      textStyle: TextStyle(color: Colors.black),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 15.0),
                                alignment: Alignment.topLeft,
                                child: TextButton(
                                    child: Text(
                                      "Change searching center",
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(
                                              color: Colors.blue.shade600),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.left,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchingTextfield =
                                            !_searchingTextfield;
                                      });
                                    }),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 30),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                        child: ScaleTransition(
                                      scale: _animation!,
                                      child: GestureDetector(
                                        onTapDown: ((details) => {
                                              if (!searching)
                                                {
                                                  print("On tap down"),
                                                  setState(() {
                                                    isSelected = true;
                                                    _spreadRadius = 1;
                                                  })
                                                }
                                            }),
                                        onTapUp: (_) {
                                          if (!searching) {
                                            print("On tap up");
                                            searching = true;
                                            globals.heroOverlay = true;
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                transitionDuration:
                                                    Duration(seconds: 2),
                                                pageBuilder: (_, __, ___) =>
                                                    buttonOverlay(),
                                              ),
                                            );
                                            postData();
                                            setState(() {
                                              _spreadRadius = 7;
                                            });
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                Hero(
                                                    tag: "searchTile",
                                                    child: Container(
                                                        //width:
                                                        //double.infinity,
                                                        //height: 140,
                                                        margin: EdgeInsets.only(
                                                            left: 15.0,
                                                            right: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Color.fromRGBO(
                                                              225,
                                                              235,
                                                              235,
                                                              1.0),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.5),
                                                              spreadRadius:
                                                                  _spreadRadius,
                                                              blurRadius: 7,
                                                              offset: Offset(0,
                                                                  3), // changes position of shadow
                                                            ),
                                                          ],
                                                        ),
                                                        alignment:
                                                            Alignment.topCenter,
                                                        child: Image.asset(
                                                            'Assets/Images/carParkbutton.png'))),
                                                if (searching &
                                                    !globals.heroOverlay)
                                                  Positioned.fill(
                                                      child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 15.0,
                                                                  right: 3),
                                                          // width: double.infinity,
                                                          //height: 200,
                                                          child:
                                                              SquarePercentIndicator(
                                                                  //width: double
                                                                  //.infinity,
                                                                  //height: double.infinity,
                                                                  //startAngle:
                                                                  // StartAngle
                                                                  //.bottomRight,
                                                                  reverse: true,
                                                                  borderRadius:
                                                                      12,
                                                                  shadowWidth:
                                                                      1.5,
                                                                  progressWidth:
                                                                      3,
                                                                  shadowColor:
                                                                      Colors
                                                                          .white70,
                                                                  progressColor:
                                                                      Colors
                                                                          .blue,
                                                                  progress:
                                                                      value /
                                                                          100))),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 1.0),
                                              child: Hero(
                                                  tag: "leftButton",
                                                  child: searching
                                                      ? ElevatedButton(
                                                          onPressed: () {
                                                            cancelSearch();
                                                            searching = false;
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                                    SnackBar(
                                                                        content:
                                                                            Text('Searching was canceled.')));
                                                          },
                                                          child: Icon(
                                                            //<-- SEE HERE
                                                            Icons.close_rounded,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            primary: Colors.red,
                                                            shape:
                                                                CircleBorder(), //<-- SEE HERE
                                                            padding:
                                                                EdgeInsets.all(
                                                                    5),
                                                          ),
                                                        )
                                                      : ElevatedButton(
                                                          child: Text(
                                                            'Search',
                                                            style: GoogleFonts
                                                                .openSans(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        13),
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            primary: Colors
                                                                .blue, //Color.fromRGBO(71, 107, 107, 1.0),
                                                            onPrimary:
                                                                Colors.white,
                                                            shadowColor:
                                                                Colors.grey,
                                                            elevation: 3,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            32.0)),
                                                            //minimumSize: Size(100, 40),
                                                          ),
                                                          onPressed: () {
                                                            isSelected = true;
                                                            searching = true;
                                                            globals.heroOverlay =
                                                                true;
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                              PageRouteBuilder(
                                                                opaque: false,
                                                                transitionDuration:
                                                                    Duration(
                                                                        seconds:
                                                                            2),
                                                                pageBuilder: (_,
                                                                        __,
                                                                        ___) =>
                                                                    buttonOverlay(),
                                                              ),
                                                            );
                                                            postData();
                                                          },
                                                        )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                    Flexible(
                                        child: ScaleTransition(
                                      scale: _animation!,
                                      child: GestureDetector(
                                        onTapDown: ((details) => {
                                              print("On tap down"),
                                              setState(() {
                                                isSelected = true;
                                                _spreadRadius = 1;
                                              })
                                            }),
                                        onTapUp: (_) async {
                                          print("On tap up");
                                          var exists =
                                              await useridExists(widget.token);
                                          if (exists == 'true') {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'You already told us you are leaving..')));
                                          } else {
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                opaque: false,
                                                transitionDuration:
                                                    Duration(seconds: 2),
                                                pageBuilder: (_, __, ___) =>
                                                    buttonOverlayRight(),
                                              ),
                                            );
                                            postData2();
                                            setState(() {
                                              _spreadRadius = 7;
                                            });
                                          }
                                        },
                                        child: Column(
                                          children: [
                                            Hero(
                                                tag: "leaveTile",
                                                child: Container(
                                                    margin: EdgeInsets.only(
                                                        right: 15.0, left: 3),
                                                    decoration: BoxDecoration(
                                                      color: Color.fromRGBO(
                                                          225, 235, 235, 1.0),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          spreadRadius: 5,
                                                          blurRadius: 7,
                                                          offset: Offset(0,
                                                              3), // changes position of shadow
                                                        ),
                                                      ],
                                                    ),
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: Image.asset(
                                                        'Assets/Images/drifting-car.png'))),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 3.0),
                                              child: Container(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: ElevatedButton(
                                                      child: Text(
                                                        'Leave',
                                                        style: GoogleFonts
                                                            .openSans(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        primary: Colors
                                                            .blue, //Color.fromRGBO(71, 107, 107, 1.0),
                                                        onPrimary: Colors.white,
                                                        shadowColor:
                                                            Colors.grey,
                                                        elevation: 3,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32.0)),
                                                        //minimumSize: Size(100, 40),
                                                      ),
                                                      onPressed: () async {
                                                        var exists =
                                                            await useridExists(
                                                                widget.token);
                                                        if (exists == 'true') {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      'You already told us you are leaving..')));
                                                        } else {
                                                          Navigator.of(context)
                                                              .push(
                                                            PageRouteBuilder(
                                                              opaque: false,
                                                              transitionDuration:
                                                                  Duration(
                                                                      seconds:
                                                                          2),
                                                              pageBuilder: (_,
                                                                      __,
                                                                      ___) =>
                                                                  buttonOverlayRight(),
                                                            ),
                                                          );
                                                          postData2();
                                                        }
                                                      })),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          )),
                        ),

                  if (showGifSearching)
                    Column(children: [
                      Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                              "Searching for parking! We will notify you when a free spot comes up!",
                              textAlign: TextAlign.center)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.white,

                          onPrimary: Colors.red,

                          shadowColor: Colors.white,

                          elevation: 3,

                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0)),

                          minimumSize: Size(100, 40), //////// HERE
                        ),
                        onPressed: () {
                          //postCancelSearch();

                          showGifSearching = false;

                          setState(() {
                            height = 100;

                            width = 100;
                          });
                        },
                        child: Text('Cancel'),
                      )
                    ]),

                  if (showGifLeaving)
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 100,
                          child: Container(
                            width: 260,
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(100)),
                              image: DecorationImage(
                                image: NetworkImage(
                                    'https://i.giphy.com/media/fOab3uALerAtdB6x4T/200.gif'),

                                //width: 200,

                                fit: BoxFit.cover,

                                //),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: 1,
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8B961),

                            value:
                                null, // Change this value to update the progress
                          ),
                        ),
                      ],
                    ),

                  if (showGifLeaving)
                    Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                            "Your empty spot has been registered! You just saved someones day!",
                            textAlign: TextAlign.center))

                  //),
                ],
              ),
            ),
          ),
        ));
  }
}
