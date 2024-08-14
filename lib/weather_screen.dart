import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info.dart';
import 'package:weather_app/hourly_forecast.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/secrets.dart';


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {

  late Future<Map<String, dynamic>> weather;

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try{
      String cityName = 'Lahore';
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey',
        )
      );
      final data = jsonDecode(res.body);

      if(int.parse(data['cod']) != 200){
        throw 'An unexpected error occured';
      }

      return data;
    }catch (e){
      throw e.toString();
    }
  }

  @override
  void initState(){
    super.initState();
    weather = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: (){
              setState(() {
                weather=getCurrentWeather();
              });
            }, 
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if(snapshot.hasError){
            return Text(snapshot.error.toString());
          }
          
          final data = snapshot.data!; 
          final currentWeatherData = data['list'] [0];
          final currentTemp = currentWeatherData ['main'] ['temp'];
          final currentSky = currentWeatherData ['weather'] [0] ['main'];
          final pressure = currentWeatherData ['main'] ['pressure'];
          final wind = currentWeatherData ['wind'] ['speed'];
          final humidity = currentWeatherData ['main'] ['humidity'];

          return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // main card

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
                        filter: ImageFilter.blur(
                          sigmaX: 10, 
                          sigmaY: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '$currentTemp K',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
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

                const SizedBox(height: 20,),

                // hourly forecast cards

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
                      final hourlyForecast = data['list'][index+1];
                      final time = DateTime.parse(hourlyForecast['dt_txt']);
                      return HourlyForecastCard(
                        
                        time: DateFormat.j().format(time), 
                        icon: hourlyForecast ['weather'] [0] ['main'] == 'Rain' 
                              || hourlyForecast ['weather'] [0] ['main'] == 'Clouds' 
                              ? Icons.cloud 
                              : Icons.sunny, 
                        temprature: hourlyForecast['main']['temp'].toString(),

                      );
                    },
                  ),
                ),

                const SizedBox(height: 20,),

                // Additional Information
                
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

