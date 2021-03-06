import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import "package:google_maps_webservice/places.dart";
import 'dart:async';
import 'package:google_maps_webservice/directions.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_key.dart';

enum TtsState { playing, stopped }
Keys apiKeys = new Keys();
final places = GoogleMapsPlaces(apiKey: apiKeys.googleMapsApiKey);
final directions = GoogleMapsDirections(apiKey: apiKeys.googleMapsApiKey);
void main() => runApp(App());

Map<int, Color> color = {
  50: Color.fromRGBO(81, 12, 118, .1),
  100: Color.fromRGBO(81, 12, 118, .2),
  200: Color.fromRGBO(81, 12, 118, .3),
  300: Color.fromRGBO(81, 12, 118, .4),
  400: Color.fromRGBO(81, 12, 118, .5),
  500: Color.fromRGBO(81, 12, 118, .6),
  600: Color.fromRGBO(81, 12, 118, .7),
  700: Color.fromRGBO(81, 12, 118, .8),
  800: Color.fromRGBO(81, 12, 118, .9),
  900: Color.fromRGBO(81, 12, 118, 1),
};

Map<int, Color> darkColor = {
  50: Color.fromRGBO(126, 87, 198, .1),
  100: Color.fromRGBO(126, 87, 198, .2),
  200: Color.fromRGBO(126, 87, 198, .3),
  300: Color.fromRGBO(126, 87, 198, .4),
  400: Color.fromRGBO(126, 87, 198, .5),
  500: Color.fromRGBO(126, 87, 198, .6),
  600: Color.fromRGBO(126, 87, 198, .7),
  700: Color.fromRGBO(126, 87, 198, .8),
  800: Color.fromRGBO(126, 87, 198, .9),
  900: Color.fromRGBO(126, 87, 198, 1),
};

MaterialColor colorCustom = MaterialColor(0xFF7E57C6, darkColor);
MaterialColor colorCustomDark = MaterialColor(0xFF510C76, color);

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart ',
      theme: ThemeData(
        primaryColor: colorCustomDark,
        primaryColorDark: colorCustomDark,
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
    if (openingCamera) {
      // Do not prompt and open camera after text is said.
      // This is here because this is called after text is said.
      openCamera();
    } else if (promptUser) {
      if (_hasSpeech) {
        await Future.delayed(const Duration(seconds: 1), () {});
        startListening();
        await Future.delayed(Duration(seconds: _expectedResponseTime), () {});
        await stop();
        // Safety of analysis
        await Future.delayed(Duration(seconds: 1), () {});

        parseSpeachResponse();
      } else {
        print("Speech recognition is not enabled.");
      }
    }
  }

  void openCamera() {
    print("Opening the camera");
    // TODO: Say weather before this.
    // Weather has been said at this time.
    // Pass directions.
    Navigator.push(
        parentContext,
        MaterialPageRoute(
          builder: (context) => CameraPreviewScanner(directions: directionsObj),
        ));
  }

  Location destinationLocation = new Location(0, 0);
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
        _newVoiceText = 'Is $nameOfPlace the correct address?';
        _expectedResponseTime = 4;
        confirmingAddress = true;
      });
      _speak();
    } else {
      print(res.errorMessage);
      setState(() {
        _newVoiceText =
            "Sorry I did not catch that. Where would you like to go?";
        _expectedResponseTime = 7;
        confirmingAddress = false;
      });
      _speak();
    }

    places.dispose();
  }

  var directionsObj;
  bool openingCamera = false;
  Future<void> getDirections() async {
    DirectionsResponse res = await directions.directionsWithLocation(
        currentlocation, destinationLocation,
        travelMode: TravelMode.walking);

    print(res.status);
    if (res.isOkay) {
      directionsObj = res;
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

  Future<void> stateWeather() async {
    String directionsInformation =
        "Perfect, you are on route to $nameOfPlace. ";
    await getData();
    directionsInformation = directionsInformation + currentWeatherConditions;
    setState(() {
      _newVoiceText = directionsInformation;
      openingCamera = true;
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
  bool promptUser;
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

  bool confirmingAddress;
  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  @override
  void initState() {
    confirmingAddress = false;
    promptUser = true;
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
    parentContext = context;
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            25.0,
          ),
          infoWindow: InfoWindow(title: "Current Location")),
      Marker(
          markerId: MarkerId("destination"),
          position: LatLng(destinationLocation.lat, destinationLocation.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            265.0,
          ),
          infoWindow: InfoWindow(title: "Destination")),
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

  String currentWeatherConditions = "";
  Future<String> getData() async {
    String cityId = "329505";
    var response = await http.get(
        Uri.encodeFull(
            "http://dataservice.accuweather.com/currentconditions/v1/$cityId?apikey=${apiKeys.accuweatherAPIKey}&details=true"),
        headers: {"Accept": "application/json"});
    setState(() {
      var data = json.decode(response.body);
      String icyConditions = checkForIcePossible(data);
      String currentConditions = getCurrentConditions(data);
      String windConditions = getWindSpeed(data);
      String weatherCondition = checkWeatherCondition(data);
      currentWeatherConditions =
          currentConditions + icyConditions + windConditions + weatherCondition;
      print(currentWeatherConditions);
    });
    return "Success";
  }

  String checkWeatherCondition(var data) {
    String condition = data[0]["WeatherText"];
    return " The current weather condition is: $condition.";
  }

  String checkForIcePossible(var data) {
    double metricAmountPrecip =
        data[0]["PrecipitationSummary"]["Past24Hours"]["Metric"]["Value"];
    double minMetric = data[0]["TemperatureSummary"]["Past24HourRange"]
        ["Minimum"]["Metric"]["Value"];
    double maxMetric = data[0]["TemperatureSummary"]["Past24HourRange"]
        ["Maximum"]["Metric"]["Value"];
    double meanOfTwoMeasurements = (minMetric + maxMetric) / 2;
    if (metricAmountPrecip > 1.0) {
      // Check for avg temp to be below freezing.
      if (meanOfTwoMeasurements < 0) {
        return " Ice is likely.";
      } else if (meanOfTwoMeasurements <= 10) {
        return " Ice is possible.";
      } else {
        return " Ice is not likely.";
      }
    }
    // Do not expect icy conditions
    if (meanOfTwoMeasurements < 0) {
      return " We are unsure if there will be ice on the route.";
    }
    return " Ice is not likely.";
  }

  String getCurrentConditions(var data) {
    String currentConditions = "";
    double imperialTemperature = data[0]["Temperature"]["Imperial"]["Value"];
    double imperialRealFeel =
        data[0]["RealFeelTemperature"]["Imperial"]["Value"];
    if (data[0]["HasPrecipitation"] == true) {
      // Check precipitation type
      currentConditions =
          ' There is currently precipitation in the form of ${data[0]["PrecipitationType"]}.';
    } else {
      currentConditions = "There is not any precipitation on the route.";
    }
    currentConditions =
        currentConditions + ' The current temperature is $imperialTemperature';
    if (imperialTemperature != imperialRealFeel) {
      return currentConditions +
          ', however, it feels like $imperialRealFeel fahrenheit.';
    } else {
      return currentConditions + "fahrenheit.";
    }
  }

  String getWindSpeed(var data) {
    double windSpeed = data[0]["Wind"]["Speed"]["Imperial"]["Value"];
    if (windSpeed >= 40) {
      return ' Caution, the wind speed is $windSpeed miles per hour.';
    }
    return ' There is not any significant wind.';
  }
}
