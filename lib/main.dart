import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Books',
      theme: new ThemeData(
        fontFamily: 'Raleway',
      ),
      home: Scaffold(
        appBar: AppBar(
            title: Text('Google Map'),
            backgroundColor: Colors.green[700],
            actions: <Widget>[]),
        body: Container(
          child: MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _homeloc = "searching...";
  Position _currentPosition;
  String gmaploc = "";
  double latitude, longitude, restlat, restlon;
  static const LatLng _center = const LatLng(6.4676929, 100.5067673);
  LatLng _lastMapPosition = _center;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController gmcontroller;
  CameraPosition _home;
  MarkerId markerId1 = MarkerId("marker");
  Set<Marker> markers = Set();
  CameraPosition _userpos;
  double screenHeight = 0.00, screenWidth = 0.00;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // ignore: unused_element
  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      // ignore: missing_return
      builder: (context, newSetState) {
        var alheight = MediaQuery.of(context).size.height;
        var alwidth = MediaQuery.of(context).size.width;

        return SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  height: 2 * (MediaQuery.of(context).size.height / 3),
                  width: MediaQuery.of(context).size.width - 10,
                  child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      mapType: _currentMapType,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 17,
                      ),
                      markers: markers.toSet(),
                      onTap: (newLatLng) {
                        _loadLoc(newLatLng, newSetState);
                      }),
                ),
                Center(
                  child: Container(
                    alignment: Alignment.topRight,
                    child: Column(
                      children: <Widget>[
                        FloatingActionButton(
                          onPressed: _onMapTypeButtonPressed,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.map, size: 36.0),
                        ),
                        Center(
                            child: Column(children: <Widget>[
                          Column(
                            children: <Widget>[
                              Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Latitude: ' + latitude.toString(),
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18),
                                  )),
                              Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Longitude: ' + longitude.toString(),
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18),
                                  )),
                              Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Latest Address: ' + _homeloc.toString(),
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18),
                                  )),
                            ],
                          ),
                        ]))
                      ],
                    ),
                  ),
                ),
              ]),
        );
      },
    );
  }

  Future<void> _getLocation() async {
    try {
      final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
      geolocator
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((Position position) async {
        _currentPosition = position;
        if (_currentPosition != null) {
          final coordinates = new Coordinates(
              _currentPosition.latitude, _currentPosition.longitude);
          var addresses =
              await Geocoder.local.findAddressesFromCoordinates(coordinates);
          setState(() {
            var first = addresses.first;
            _homeloc = first.addressLine;
            if (_homeloc != null) {
              latitude = _currentPosition.latitude;
              longitude = _currentPosition.longitude;
              return;
            }
          });
        }
      }).catchError((e) {
        print(e);
      });
    } catch (exception) {
      print(exception.toString());
    }
  }

  void _loadLoc(LatLng loc, newSetState) async {
    newSetState(() {
      print("insetstate");
      markers.clear();
      latitude = loc.latitude;
      longitude = loc.longitude;
      _getLocationfromlatlng(latitude, longitude, newSetState);
      _home = CameraPosition(
        target: loc,
        zoom: 16,
      );
      markers.add(Marker(
        markerId: markerId1,
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: 'New Location',
          snippet: 'New Mark Location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    });
    _userpos = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 17,
    );
    _newhomeLocation();
  }

  _getLocationfromlatlng(double lat, double lng, newSetState) async {
    final Geolocator geolocator = Geolocator()
      ..placemarkFromCoordinates(lat, lng);
    _currentPosition = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //debugPrint('location: ${_currentPosition.latitude}');
    final coordinates = new Coordinates(lat, lng);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    newSetState(() {
      _homeloc = first.addressLine;
      if (_homeloc != null) {
        latitude = lat;
        longitude = lng;
        return;
      }
    });
    setState(() {
      _homeloc = first.addressLine;
      if (_homeloc != null) {
        latitude = lat;
        longitude = lng;
        return;
      }
    });
  }

  Future<void> _newhomeLocation() async {
    gmcontroller = await _controller.future;
    gmcontroller.animateCamera(CameraUpdate.newCameraPosition(_home));
  }
}
