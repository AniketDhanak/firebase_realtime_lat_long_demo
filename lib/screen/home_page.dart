import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'package:app_settings/app_settings.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late DatabaseReference databaseReference;
  Permission? _permission;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  var currentLat = 0.0;
  var currentLng = 0.0;
  var currentLocation = "";
  Timer? timer;
  int incrementCounter = 0;

  @override
  void initState() {
    super.initState();
    databaseReference = FirebaseDatabase.instance.ref();
    _permission = Permission.location;
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      getLocation();
    });
    getLocation();
  }

  addDataToList(dynamic id, String lat, String long) {
    databaseReference
        .child('MapData')
        .child(id.toString())
        .set({"lat": lat, "long": long});
  }

  updateData(dynamic id, String lat, String long){
    databaseReference
        .child('MapData')
        .child('0')
        .update({"lat": lat, "long": long});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  getLocation() {
    log("getLocation");
    if (Platform.isIOS) {
      log("Ios");
      _determinePosition().then((value) {
        setState(() {
          incrementCounter = incrementCounter + 1;
          currentLat = value.latitude;
          currentLng = value.longitude;
        });
        addDataToList(incrementCounter,currentLat.toString(),currentLng.toString());
        log(currentLat.toString());
        log(currentLng.toString());
      });
    } else {
      _listenForPermissionStatus();
    }
  }

  void _listenForPermissionStatus() async {
    log("Listen");
    final status = await _permission!.status;
    _permissionStatus = status;
    if (_permissionStatus.isGranted) {
      log("grandted");
      _determinePosition();
    }
    if (_permissionStatus.isDenied) {
      requestPermission(_permission!);
    }
    if (_permissionStatus.isPermanentlyDenied) {
      openAppSettings();
    }
    log("Listen: $_permissionStatus");
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();

    _permissionStatus = status;
    if (status.isGranted) {
      _determinePosition();
    }
    if (Platform.isAndroid) {
      if (status.isDenied) {
        openAppSettings();
      }
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    log("determinePermission $serviceEnabled");

    if (serviceEnabled) {
      permission = await Geolocator.requestPermission();
      log("serviceEnabled $serviceEnabled");

      return await Geolocator.getCurrentPosition().then((value) {
        log("getCurrentPosition: $value");
        setState(() {
          incrementCounter = incrementCounter + 1;
          currentLat = value.latitude;
          currentLng = value.longitude;
        });
        updateData(incrementCounter,currentLat.toString(),currentLng.toString());
        // getLocationName(value.latitude, value.longitude);
        // changePosition(value.latitude, value.longitude);

        return value;
      });
    }
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      log("!serviceEnabled $serviceEnabled");
      openAppSettings();
     // AppSettings.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Delivery Boy App"),),
      body: Column(
        children: [
          Text(
            "lat: ${currentLat}",
            style: TextStyle(
              fontSize: 34,
              color: Colors.black
            ),
          ),
          Text(
            "Long: ${currentLng}",
            style: TextStyle(
              fontSize: 34,
              color: Colors.black
            ),
          ),
        ],
      ),
    );
  }
}
