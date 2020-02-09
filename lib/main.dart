import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Weather'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
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
            "http://dataservice.accuweather.com/currentconditions/v1/$cityId?apikey=MgM72YaXfJBWfOAdd6ebahZmM8eT5zAA&details=true"),
        headers: {"Accept": "application/json"});
    setState(() {
      var data = json.decode(response.body);
      String icyConditions = checkForIcePossible(data);
      String currentConditions = getCurrentConditions(data);
      String windConditions = getWindSpeed(data);
      String weatherCondition = checkWeatherCondition(data);
      currentWeatherConditions = currentConditions + icyConditions + windConditions + weatherCondition;
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
    double imperialRealFeel = data[0]["RealFeelTemperature"]["Imperial"]["Value"];
    if (data[0]["HasPrecipitation"] == true) {
      // Check precipitation type
      currentConditions =
          ' There is currently precipitation in the form of ${data[0]["PrecipitationType"]}.';
    } else {
      currentConditions = "There is not any precipitation on the route.";
    }
    currentConditions = currentConditions +
        ' The current temperature is $imperialTemperature';
    if (imperialTemperature !=
        imperialRealFeel) {
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
    return ' No significant wind.';
  }

}
