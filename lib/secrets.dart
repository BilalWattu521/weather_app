import 'package:flutter_dotenv/flutter_dotenv.dart';

final openWeatherAPIKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
