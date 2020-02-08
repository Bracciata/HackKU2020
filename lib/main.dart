import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart ',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Weather'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.star),
              onPressed: () {
                getData();
              },
            )
          ],
        ),
      ),
    );
  }

  String currentWeatherConditions = "";
  Future<String> getData() async {
    String cityId = "329505";
    var response = await http.get(
        Uri.encodeFull(
            "http://dataservice.accuweather.com/currentconditions/v1/${cityId}?apikey=GCGPPsIXMqZTvKobbvEvuSzCPusRNC8z&details=true"),
        headers: {"Accept": "application/json"});
    setState(() {
      var data = json.decode(response.body);
      print(data);
      String icyConditions = checkForIcePossible(data);
      String currentConditions = getCurrentConditions(data);
      currentWeatherConditions = currentConditions + icyConditions;
    });
    return "Success";
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
        return "Ice is not likely.";
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
    if (data[0]["HasPrecipitation"] == true) {
      // Check percip type
      currentConditions =
          ' There is currently percipitation in the form of ${data[0]["PrecipitationType"]}.';
    } else {
      currentConditions = "There is not any percipitation on the route.";
    }
    currentConditions = currentConditions +
        ' The current temperature is ${data[0]["Temperature"]["Imperial"]["Value"]}';
    if (data[0]["Temperature"]["Imperial"]["Value"] !=
        data[0]["RealFeelTemperature"]["Imperial"]["Value"]) {
      return currentConditions +
          ', however, it feels like ${data[0]["RealFeelTemperature"]["Imperial"]["Value"]} fahrenheit.';
    } else {
      return currentConditions + "fahrenheit.";
    }
  }
}
