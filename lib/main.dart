import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:pasthelwparking_v1/screens/parking_location.dart';
import 'package:pasthelwparking_v1/screens/claim.dart';
import 'package:pasthelwparking_v1/screens/enableLocation.dart';
import 'package:pasthelwparking_v1/screens/login.dart';
import 'screens/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pasthelwparking_v1/pushnotificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_overlay/flutter_overlay.dart';
import 'dart:convert' as cnv;
import 'model/notifications.dart';
import 'SqliteService.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
        child: MaterialApp(
      title: 'pasthelwparking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      //home: IntroScreen(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //initialize firebase values
  late final FirebaseMessaging _messaging;
  PushNotification? _notificationInfo, notification;
  static String id = '';
  String? token, address;
  DateTime? notifReceiveTime;
  Position? _currentPosition;
  double height = 100;

  double width = 100;

  double latitude = 0, longitude = 0;

  int index = 0, count = 0;

  bool showGifSearching = false;

  bool showGifLeaving = false;

  late Future _getPosition, _getAddress, _getToken, _getSP;

  OverlayState? overlayState;

  SqliteService sqliteService = SqliteService();

  bool? entered;
  var page;
  late SharedPreferences prefs;
  String? s_uid;

  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  late String serviceStatusValue;

  Future _getDevToken() async {
    s_uid = prefs.getString("uid");
    token = await FirebaseMessaging.instance.getToken();
    if (s_uid == null && prefs.getString('email') != null) {
      print("TOKEN NULL $token");
      prefs.setString("uid", token!);
      updateUID();
    } else {
      if (s_uid != token && prefs.getString('email') != null) {
        print("TOKEN NOT EQUAL $token $s_uid");
        updateUID();
      }
    }
    print("DEV TOKEN FIREBASE CLOUD MESSAGING -> $token");
  }

  void _show(data, token) {
    HiOverlay.show(
      context,
      child: _claimPopup(data, token),
    ).then((value) {
      print('---received:$value');
    });
  }

  _claimPopup(data, token) {
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
                    if (data["cartype"] == "Sedan")
                      Image.asset('Assets/Images/Sedan.png')
                    else if (data["cartype"] == "Coupe")
                      Image.asset('Assets/Images/Coupe.png')
                    else if (data["cartype"] == "Pickup")
                      Image.asset('Assets/Images/Pickup.png')
                    else if (data["cartype"] == "Jeep")
                      Image.asset('Assets/Images/Jeep.png')
                    else if (data["cartype"] == "Wagon")
                      Image.asset('Assets/Images/Wagon.png')
                    else if (data["cartype"] == "Crossover")
                      Image.asset('Assets/Images/Crossover.png')
                    else if (data["cartype"] == "Hatchback")
                      Image.asset('Assets/Images/Hatchback.png')
                    else if (data["cartype"] == "Van")
                      Image.asset('Assets/Images/Van.png')
                    else if (data["cartype"] == "Sportcoupe")
                      Image.asset('Assets/Images/Sportcoupe.png')
                    else if (data["cartype"] == "SUV")
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
                        postClaim(data);
                        Navigator.pop(context, 'close');
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ParkingLocation(
                                data, latitude, longitude, token)));
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

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp();
    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Parse the message received
        notifReceiveTime = DateTime.now();
        postInsertTime();
        notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );
        if (notification != null) {
          getLatLon(token);
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(notification!.title!),
            subtitle: Text(notification!.body!),
            background: Colors.cyan.shade700,
            duration: Duration(seconds: 2),
          );

          Notifications ntf = Notifications.empty();
          ntf.address = address.toString();
          ntf.carType = "Sedan";
          ntf.time = message.data["time"];
          ntf.status = "Pending";
          ntf.entry_id = message.data["id"].toString();
          id = await sqliteService.createItem(ntf);
          _show(message.data, token);
          setState(() {});
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future notificationsCount() async {
    count = await SqliteService().getNotificationCount();
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  postData() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/searching.php"),
          body: {"lat": '11.44', "long": '11.44', "uid": token});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  postInsertTime() async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/insert_time.php"),
          body: {"time": '$notifReceiveTime', "uid": '$token'});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  postClaim(data) async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/claim.php"),
          body: {"uid": data["user_id"], "claimedby_id": token});
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  getLatLon(userid) async {
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/getUserLatLon.php"),
          body: {"uid": userid});
      print("LATLON " + response.body);
      var data = "[" + response.body + "]";
      var datajson = cnv.jsonDecode(response.body);
      print(datajson["lat"]);
      latitude = double.parse(datajson["lat"]);
      longitude = double.parse(datajson["long"]);
    } catch (e) {
      print(e);
    }
  }

  checkForInitialState() async {
    //await Firebase.initializeApp();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      print('initialMessage data: ${initialMessage?.data}');
      if (initialMessage != null) {
        PushNotification notification = PushNotification(
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
        );
      }
    });
  }

  updateUID() async {
    var mail = prefs.getString("email");
    print(mail);
    try {
      var response = await http.post(
          //Uri.parse("http://10.0.2.2:8080/pasthelwparking/searching.php"), //vm
          Uri.parse(
              "https://pasthelwparkingv1.000webhostapp.com/php/updateID.php"),
          body: {"email": mail, "uid": token});
      print("UPDATE UID ${response.body}");
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
      );
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              ClaimPage(message.data, token!, latitude, longitude)));
    });
    //when app is terminated
    checkForInitialState();

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getPosition = _determinePosition();
    _getSP = sharedPref();
    registerNotification();
    overlayState = Overlay.of(context);
    _toggleServiceStatusStream();
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // These are the callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        print("???resumed");
        if (serviceStatusValue == 'enabled') {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MyHomePage()),
              (Route route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => EnableLocation()),
              (Route route) => false);
        }
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        print("???inactive");
        break;
      case AppLifecycleState.paused:
        // widget is paused
        print("???paused");
        break;
      case AppLifecycleState.detached:
        // widget is detached
        print("???detached");
        break;
    }
  }

  _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        if (serviceStatus == ServiceStatus.enabled) {
          updateStatus('enabled');
        } else {
          updateStatus('disabled');
        }
      });
    }
  }

  void updateStatus(String value) {
    if (serviceStatusValue != value) {
      setState(() {
        serviceStatusValue = value;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (BuildContext context) => super.widget));
      });
    }
  }

  Future _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceStatusValue = 'disabled';
      return Future.error('Location services are disabled.');
    } else {
      serviceStatusValue = 'enabled';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentPosition = position;
        address =
            "${place.locality}, ${place.subLocality},${place.street}, ${place.postalCode}";
        print("///// $address");
      });
    } catch (e) {
      print(e);
    }
  }

  Future sharedPref() async {
    prefs = await SharedPreferences.getInstance();
    //await prefs.clear();
    entered = prefs.getBool("isLoggedIn");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait(
            [_getPosition, _getDevToken(), notificationsCount(), sharedPref()]),
        builder: (context, snapshot) {
          // Future done with no errors
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            if (entered == null || entered == false) {
              return LoginPage();
            } else {
              return HomePage(address, token, _currentPosition!.latitude,
                  _currentPosition!.longitude, count);
            }
          }

          // Future with some errors
          else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return EnableLocation();
          } else {
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
