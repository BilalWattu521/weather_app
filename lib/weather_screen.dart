import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info.dart';
import 'package:weather_app/hourly_forecast.dart';
import 'package:weather_app/secrets.dart';
import 'package:http/http.dart' as http;


enum TemperatureUnit { kelvin, celsius, fahrenheit }

String formatTemperature(double kelvinTemp, TemperatureUnit unit) {
  switch (unit) {
    case TemperatureUnit.celsius:
      return '${(kelvinTemp - 273.15).toStringAsFixed(1)} °C';
    case TemperatureUnit.fahrenheit:
      return '${((kelvinTemp - 273.15) * 9 / 5 + 32).toStringAsFixed(1)} °F';
    case TemperatureUnit.kelvin:
    return '${kelvinTemp.toStringAsFixed(1)} K';
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;
  String cityName = 'Lahore';
  final TextEditingController _searchController = TextEditingController();
  TemperatureUnit selectedUnit = TemperatureUnit.celsius;

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&APPID=$openWeatherAPIKey',
        ),
      );
      final data = jsonDecode(res.body);

      if (int.parse(data['cod']) != 200) {
        throw 'City not found or API error';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather(cityName);
  }

void _searchCity(String city) {
  if (city.trim().isEmpty) return;
  setState(() {
    cityName = city.trim().toUpperCase();
    weather = getCurrentWeather(cityName);
    _searchController.clear();
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeather(cityName);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city...',
                filled: true,
                fillColor: Colors.white24,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _searchCity(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                _searchCity(value);
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];
          final currentTemp = (currentWeatherData['main']['temp'] as num).toDouble();
          final currentSky = currentWeatherData['weather'][0]['main'];
          final pressure = currentWeatherData['main']['pressure'];
          final wind = currentWeatherData['wind']['speed'];
          final humidity = currentWeatherData['main']['humidity'];

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  cityName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatTemperature(currentTemp, selectedUnit),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    DropdownButton<TemperatureUnit>(
                                      value: selectedUnit,
                                      dropdownColor: Colors.grey[800],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      underline: Container(),
                                      items: TemperatureUnit.values.map((unit) {
                                        return DropdownMenuItem(
                                          value: unit,
                                          child: Text(
                                            unit == TemperatureUnit.kelvin
                                                ? 'K'
                                                : unit == TemperatureUnit.celsius
                                                    ? '°C'
                                                    : '°F',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newUnit) {
                                        if (newUnit != null) {
                                          setState(() {
                                            selectedUnit = newUnit;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Icon(
                                  currentSky == 'Clouds' || currentSky == 'Rain'
                                      ? Icons.cloud
                                      : Icons.sunny,
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  currentSky,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index + 1];
                        final time = DateTime.parse(hourlyForecast['dt_txt']);
                        final hourlyTemp = (hourlyForecast['main']['temp'] as num).toDouble();

                        return HourlyForecastCard(
                          time: DateFormat.j().format(time),
                          icon: hourlyForecast['weather'][0]['main'] == 'Rain' ||
                                  hourlyForecast['weather'][0]['main'] == 'Clouds'
                              ? Icons.cloud
                              : Icons.sunny,
                          temprature: formatTemperature(hourlyTemp, selectedUnit),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfo(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: '$humidity',
                      ),
                      AdditionalInfo(
                        icon: Icons.air,
                        label: 'Wind Speed',
                        value: '$wind',
                      ),
                      AdditionalInfo(
                        icon: Icons.beach_access,
                        label: 'Pressure',
                        value: '$pressure',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
