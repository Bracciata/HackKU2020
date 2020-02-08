import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import "package:google_maps_webservice/places.dart";
import 'dart:async';
import 'dart:io';
import 'package:google_maps_webservice/directions.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum TtsState { playing, stopped }

final places =
    GoogleMapsPlaces(apiKey: 'AIzaSyC_alUaPxZr-P7wTRhNLYFgM6Yj5XgHQ40');
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
  // text to speech
  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.4;
  // speech to text
  bool _hasSpeech = false;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  final SpeechToText speech = SpeechToText();

  // text to speech
  String _newVoiceText =
      "Hello, Welcome to CrossGuard. Where would you like to go? ";

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  initTts() {
    flutterTts = FlutterTts();

    _getLanguages();

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
        prompt();
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        var result = await flutterTts.speak(_newVoiceText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  Future stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  // speech to text
  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);

    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  int _expectedResponseTime = 7;
  // Prompt is called after _speak is called to say anything in this file.
  // Prompt activates the mic and then calls the parser.
  Future<void> prompt() async {
    if(openingCamera){
      // Do not prompt and open camera after text is said.
      // This is here because this is called after text is said.
      openCamera();
    }
    else if (promptUser) {

    if (_hasSpeech) {
        await Future.delayed(const Duration(seconds: 1), () {});
        startListening();
        await Future.delayed(Duration(seconds: _expectedResponseTime), () {});
        stop();
        // Safety of analysis
        await Future.delayed(Duration(seconds: 1), () {});

        parseSpeachResponse();
      
  
    } else {
      print("Speech recognition is not enabled.");
    }
    }
  }
void openCamera(){
  print("Opening the camera");
  // TODO: Say weather before this.
  // Weather has been said at this time sooooooooooo.
  // Pass directions.
  Navigator.push(
    parentContext,
    MaterialPageRoute(
      builder: (context) => Camera(directionsObj: directions),
    ));
}
  Location destinationLocation;
  Future<void> findLocation(String query) async {
    String sessionToken = 'xyzabc_1234';
    PlacesAutocompleteResponse res;
    try {
      res = await places.autocomplete(query, sessionToken: sessionToken);
    } catch (Exception) {
      setState(() {
        confirmingAddress = true;
        _newVoiceText =
            "Sorry I did not catch that, is $nameOfPlace where you would like to go?";
        _expectedResponseTime = 4;
      });
      _speak();
      return;
    }
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
      setState(() {
        nameOfPlace = details.result.formattedAddress;
      });
      print(details.result.formattedAddress);
      print(details.result.formattedPhoneNumber);
      print(details.result.url);
      double latDest = details.result.geometry.location.lat;
      double lngDest = details.result.geometry.location.lng;
      destinationLocation = Location(latDest, lngDest);
      // Ask if location is correct and if so proceed.
      setState(() {
        _newVoiceText =
            'Is $nameOfPlace the correct address?';
        _expectedResponseTime = 4;
        confirmingAddress = true;
      });
      await Future.delayed(const Duration(seconds: 1), () {});
      _speak();
    } else {
      print(res.errorMessage);
      setState(() {
        _newVoiceText =
            "Sorry I did not catch that. Where would you like to go?";
        _expectedResponseTime = 7;
        confirmingAddress = false;
      });
      await Future.delayed(const Duration(seconds: 1), () {});
      _speak();
    }

    places.dispose();
  }
  var directions;
  bool openingCamera = false;
  Future<void> getDirections() async {
    DirectionsResponse res = await directions.directionsWithLocation(
        currentlocation, destinationLocation,
        travelMode: TravelMode.walking);

    print(res.status);
    if (res.isOkay) {
      directions = res;
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
  void stateWeather(){
    String directionsInformation = "Perfect, you are on route to $nameOfPlace. ";

    setState(() {
      _newVoiceText = directionsInformation;
    });
    _speak();
  }
  String nameOfPlace;
  Future<void> parseSpeachResponse() async {
    String parseWords = lastWords.toLowerCase();
    if (confirmingAddress) {
      if (parseWords.contains("yes")) {
        // Using the address go to the location.
        await getDirections();
        // Speak about weather then start journey and pass directions
        stateWeather();
        // Send the directions to camera.
        // After weather is stated the camera will open
      } else if (parseWords.contains("no")) {
        // End and repeat end of file
        setState(() {
          confirmingAddress = false;
          _newVoiceText = "My bad. Where would you like to go?";
          _expectedResponseTime = 7;
        });
        await Future.delayed(const Duration(seconds: 1), () {});
        _speak();
      } else {
        setState(() {
          confirmingAddress = true;
          _newVoiceText =
              "Sorry I did not catch that, is $nameOfPlace where you would like to go?";
          _expectedResponseTime = 4;
        });
        _speak();
      }
    } else {
      if (parseWords.contains("stop")) {
        setState(() {
          _newVoiceText = "Okay, goodbye!";
          promptUser = false;
        });

        _speak();
      } else if (parseWords == null || parseWords == '') {
        setState(() {
          _newVoiceText =
              "Oops I didn't catch that, where would you like to go?";
          _expectedResponseTime = 7;
          confirmingAddress = false;
        });

        _speak();
      } else {
        print('Looking for the location $parseWords.');
        await findLocation(parseWords);
      }
    }
  }

  // TODO: When prompting is it the correct location add a marker for the location because that is cool.
  bool promptUser = true;
  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(onResult: resultListener);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {});
  }

  void cancelListening() {
    speech.cancel();
    setState(() {});
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  bool confirmingAddress = false;
  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
    initTts();
    _speak();
    initSpeechState();
  }

  void getCurrentLocation() async {
    Position res = await Geolocator().getCurrentPosition();
    setState(() {
      position = res;
      currentlocation = Location(res.latitude, res.longitude);
      _child = mapWidget();
    });
  }
  BuildContext parentContext;
  @override
  Widget build(BuildContext context) {
    parentContext=context;
    return Scaffold(
      appBar: AppBar(
        title: Text('CrossGuard'),
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
}
