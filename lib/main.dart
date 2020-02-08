import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import "package:google_maps_webservice/places.dart";
import 'dart:async';
import 'dart:io';
import 'package:google_maps_webservice/directions.dart';

final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyC_alUaPxZr-P7wTRhNLYFgM6Yj5XgHQ40');
final directions =
    GoogleMapsDirections(apiKey: 'AIzaSyC_alUaPxZr-P7wTRhNLYFgM6Yj5XgHQ40');
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
  Location currentlocation;
  Widget _child;
  @override
  void initState() {
    // TODO
    getCurrentLocation();
    //TODO: Remove this line below.
    findLocation('allen fieldhouse');
    super.initState();
  }

  void getCurrentLocation() async {
    Position res = await Geolocator().getCurrentPosition();
    setState(() {
      position = res;
      currentlocation = Location(res.latitude, res.longitude);
      _child = mapWidget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps'),
      ),
      body: _child,
    );
  }

  Set<Marker> _createMarker() {
    return <Marker>[
      Marker(
          markerId: MarkerId("current_location"),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: "Current Location")),
    ].toSet();
  }

  Widget mapWidget() {
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

  Future<void> findLocation(String query) async {
    String sessionToken = 'xyzabc_1234';
    PlacesAutocompleteResponse res =
        await places.autocomplete(query, sessionToken: sessionToken);

    if (res.isOkay) {
      // list autocomplete prediction
      for (var p in res.predictions) {
        print('- ${p.description}');
      }

      // get detail of the first result
      PlacesDetailsResponse details = await places.getDetailsByPlaceId(
          res.predictions.first.placeId,
          sessionToken: sessionToken);

      print('\nDetails :');
      print(details.result.formattedAddress);
      print(details.result.formattedPhoneNumber);
      print(details.result.url);
      double latDest = details.result.geometry.location.lat;
      double lngDest = details.result.geometry.location.lng;
      Location locationOfDestination = Location(latDest, lngDest);
      // Ask if location is correct and if so proceed.
      // If yes
      getDirections(locationOfDestination);
    } else {
      print(res.errorMessage);
    }

    places.dispose();
  }
  Future<void> getDirections(Location destinationLocation)async{
   DirectionsResponse res =
      await directions.directionsWithLocation(currentlocation,destinationLocation,travelMode: TravelMode.walking);

  print(res.status);
  if (res.isOkay) {
    print('${res.routes.length} routes');
    for (var r in res.routes) {
      print(r.summary);
      print(r.bounds);
    }
  } else {
    print(res.errorMessage);
  }

  directions.dispose();
}
}
