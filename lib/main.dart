import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(App());
 
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Google Maps',
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController _controller;
  Position position; // USE THIS FOR CURRENT LOCATION
  Widget _child;
  @override 
  void initState() {
    // TODO
    getCurrentLocation();
    super.initState();
  }
  void getCurrentLocation() async{
    Position res = await Geolocator().getCurrentPosition();
    setState((){
      position = res;
      _child = mapWidget();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar (
        title: Text('Google Maps'),
      ),
      body: _child,
    );
  }
  Set<Marker> _createMarker(){
    return <Marker>[
      Marker(
        markerId: MarkerId("current_location"),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: "Current Location")
      ),
    ].toSet();
  }
  Widget mapWidget(){
    return GoogleMap(
      mapType: MapType.normal,
      markers: _createMarker(),
      initialCameraPosition: CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
      },
    );
  }
}