// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'detector_painters.dart';
import 'scanner_utils.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class CameraPreviewScanner extends StatefulWidget {
  final DirectionsResponse directions;

  const CameraPreviewScanner({Key key, this.directions}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CameraPreviewScannerState();
}

class _CameraPreviewScannerState extends State<CameraPreviewScanner> {
  dynamic _scanResults;
  CameraController _camera;
  Detector _currentDetector = Detector.cloudLabel;
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;
  final ImageLabeler _cloudImageLabeler =
      FirebaseVision.instance.cloudImageLabeler();

  @override
  void initState() {
    initTts();
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS
          ? ResolutionPreset.low
          : ResolutionPreset.medium,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      ScannerUtils.detect(
        image: image,
        detectInImage: _cloudImageLabeler.processImage,
        imageRotation: description.sensorOrientation,
      ).then(
        (dynamic results) {
          if (_currentDetector == null) return;
          setState(() {
            _scanResults = results;
          });
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  Widget _buildResults() {
    const Text noResultsText = Text('No results!');

    if (_scanResults == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );
    if (_scanResults is! List<ImageLabel>) return noResultsText;
    painter = LabelDetectorPainter(imageSize, _scanResults);
    checkForTrafficLights(_scanResults);

    return CustomPaint(
      painter: painter,
    );
  }
  String lastOptionWas="STOP";
  void checkForTrafficLights(var results) {
    print(results);
    int x = 7;
    for (var result in results){
      
      if(result.text=="Blue"&& result.confidence>.98 ){
        if(lastOptionWas!="STOP"){
          lastOptionWas = "STOP";
          setState(() {
            _newVoiceText = "Stop for the traffic light.";
          });
          _speak();
        }
        // Stop
    }else if(result.text=="Leaf"&& result.confidence>.9){

        if(lastOptionWas!="GO"){
          lastOptionWas = "GO";
                    setState(() {
            _newVoiceText = "Cross through the cross walk.";
          });
          _speak();
        }
    }
    }

  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 30.0,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(_camera),
                _buildResults(),
              ],
            ),
    );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }

    await _camera.stopImageStream();
    await _camera.dispose();

    setState(() {
      _camera = null;
    });

    _initializeCamera();
  }

  var stepsList;
  void getAllStepsAndRelevantInfo() {
    var waypoints = directions.routes.first.legs.first.steps.iterator;
    stepsList = [];
    while (waypoints.moveNext()) {
      stepsList.add(waypoints.current);
      print("Adding to steps list.");
    }
    print(stepsList);
  }

  int currentLocationStepIndex = -1;
  Future<void> checkLocation() async {
    // Check if close enough and not the same index.
    await getCurrentLocation();
    int index = 0;
    for (var item in stepsList) {
      if (currentLocationStepIndex != index) {
        bool withinRange = false;
        Location locOfStart = item.startLocation;
        if ((locOfStart.lat - currentLocation.lat).abs() < .0002 &&
            (locOfStart.lng - currentLocation.lng).abs() < .0002) {
          withinRange = true;
        }
        if (withinRange) {
          // Say
          currentLocationStepIndex = index;

          String say;
          try {
            if (item.maneuver == null) {
              say =
                  'Go ${item.distance.text}. This will take approximately ${item.duration.text}';
            } else {
              say =
                  '${item.maneuver} then go ${item.distance.text}. This will take approximately ${item.duration.text}';
            }
          } catch (Exception) {
            say =
                'Go ${item.distance.text}. This will take approximately ${item.duration.text}';
          }
          currentLocationStepIndex = index;
          if (index == stepsList.length) {
            say = "You have arrived!";
            // Notify them and close the app.
            // You have arrived
          }
          setState(() {
            _newVoiceText = say;
          });
          _speak();
        }
      }
      index += 1;
    }
  }

  Location currentLocation;
  void getCurrentLocation() async {
    Position res = await Geolocator().getCurrentPosition();
    setState(() {
      currentLocation = Location(res.latitude, res.longitude);
    });
  }

  // text to speech
  String _newVoiceText =
      "Hello, Welcome to CrossGuard. Where would you like to go? ";
  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.4;
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

  var directions;
  @override
  Widget build(BuildContext context) {
    print(widget.directions);
    directions = widget.directions;
    _currentDetector = Detector.cloudLabel;
    getAllStepsAndRelevantInfo();
    checkLocation();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross Guard'),
      ),
      body: _buildImage(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCameraDirection,
        child: _direction == CameraLensDirection.back
            ? const Icon(Icons.camera_front)
            : const Icon(Icons.camera_rear),
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {
      _cloudImageLabeler.close();
    });

    _currentDetector = null;
    super.dispose();
  }
}
