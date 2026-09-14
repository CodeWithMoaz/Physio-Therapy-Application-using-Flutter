import 'dart:convert';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:physiotherapy/models/workout_plan_model.dart';
import 'package:physiotherapy/api_service/api_config.dart';

class WorkoutPlanService {
  final String apiKey;
  final String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  WorkoutPlanService({String? apiKey})
      : apiKey = apiKey ?? ApiConfig.getApiKey();

  Future<WorkoutPlan> generateWorkoutPlan({
    required String targetArea,
    required String bodyType,
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) async {
    print('\n=== Starting Workout Plan Generation ===');
    print('Target Area: $targetArea');
    print('Body Type: $bodyType');
    print('Gender: $gender');
    print('Weight: ${weight}kg');
    print('Height: ${height}cm');
    print('Age: $age');

    final prompt = '''
Generate a detailed strengthening workout plan for the following specifications:

Target Area: $targetArea
Body Type: $bodyType
Gender: $gender
Weight: ${weight}kg
Height: ${height}cm
Age: $age

Please provide a structured workout plan in the following format:

# [TARGET AREA] Rehabilitation Plan for [BODY TYPE]

## Description
[2-3 sentences describing the overall approach and goals]

## Precautions
* [precaution 1]
* [precaution 2]
* [precaution 3]

## Week 1
### Focus: [Week 1 focus]
### Intensity: [Week 1 intensity]

#### Day 1
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 2
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 3
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 4
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 5
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 6
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 7
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

## Week 2
### Focus: [Week 2 focus]
### Intensity: [Week 2 intensity]

#### Day 1
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 2
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 3
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 4
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 5
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 6
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

#### Day 7
* Exercise 1: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

* Exercise 2: [Name]
  Sets: [number]
  Reps: [number]
  Duration: [time]
  Difficulty: [level]
  Equipment: [list]
  Instructions: [step by step]

## Metrics
* BMI: [value]
* Target Weight: [value]
* Calorie Goal: [value]

Important:
- Ensure all exercise details (Sets, Reps, Duration, Difficulty, Equipment, Instructions) for a single exercise are contained within the same markdown bullet point, each on a new line but *without* an additional bullet or hyphen prefix.
- If a value is not applicable (e.g., duration for a rep-based exercise), use "N/A".
- Equipment and Instructions should be comma-separated lists if multiple items.
- Provide at least 3-5 exercises per day.
- Ensure all weeks and days are included as per the plan template.
''';

    try {
      print('\n=== Making API Request ===');
      print('API Key length: ${apiKey.length}');
      print('Base URL: $baseUrl');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'physiotherapy-app',
          'X-Title': 'Physiotherapy App',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-exp:free',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a physiotherapy expert specialized in creating personalized rehabilitation workout plans. Format your responses in markdown with clear sections for weeks, days, and exercises.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      );

      print('\n=== API Response ===');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Response received successfully');

        if (jsonResponse['choices'] == null ||
            jsonResponse['choices'].isEmpty) {
          print('Error: API returned empty choices array');
          return WorkoutPlan.empty();
        }

        final aiResponse = jsonResponse['choices'][0]['message']['content'];
        print('\n=== AI Response Preview ===');
        print(
            aiResponse.substring(0, min<int>(200, aiResponse.length)) + '...');

        if (aiResponse == null || aiResponse.toString().trim().isEmpty) {
          print('Error: Empty AI response');
          return WorkoutPlan.empty();
        }

        print('\n=== Parsing Workout Plan ===');
        final workoutPlan = _parseWorkoutPlan(aiResponse, targetArea, bodyType);

        print('\n=== Workout Plan Generated ===');
        print('Number of weeks: ${workoutPlan.weeks.length}');
        print('Number of precautions: ${workoutPlan.precautions.length}');
        print('Description length: ${workoutPlan.description.length}');

        return workoutPlan;
      } else {
        print('API Error: ${response.statusCode}');
        print('Error Response: ${response.body}');
        return WorkoutPlan.empty();
      }
    } catch (e) {
      print('\n=== Error Generating Workout Plan ===');
      print('Error: $e');
      return WorkoutPlan.empty();
    }
  }

  WorkoutPlan _parseWorkoutPlan(
      String markdownResponse, String targetArea, String bodyType) {
    try {
      print('\n=== Parsing Markdown Response ===');

      String htmlContent = md.markdownToHtml(markdownResponse);
      var document = html_parser.parse(htmlContent);

      String description = '';
      var descSection = _findSectionByHeading(document, 'description');
      if (descSection != null) {
        description = descSection.text.trim();
        print(
            'Description extracted: ${description.substring(0, min<int>(50, description.length))}...');
      }

      List<String> precautions = [];
      var precautionsSection = _findSectionByHeading(document, 'precautions');
      if (precautionsSection != null) {
        precautions = _extractListItems(precautionsSection);
        print('Precautions extracted: ${precautions.length} items');
      }

      List<Week> weeks = [];
      var currentElement = document.body?.children.first;
      print('\n=== Extracting Weeks ===');

      while (currentElement != null) {
        if (currentElement.localName == 'h2' &&
            currentElement.text.toLowerCase().contains('week')) {
          var weekSection = currentElement;
          var weekNumber = int.tryParse(
                  weekSection.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              1;
          print('Processing Week $weekNumber');

          String focus = '';
          String intensity = 'Moderate';
          List<Day> days = [];

          var innerElement = weekSection.nextElementSibling;
          while (innerElement != null &&
              !innerElement.localName!.startsWith('h2')) {
            if (innerElement.text.toLowerCase().contains('focus:')) {
              focus = innerElement.text.split(':')[1].trim();
            } else if (innerElement.text.toLowerCase().contains('intensity:')) {
              intensity = innerElement.text.split(':')[1].trim();
            } else if (innerElement.localName == 'h4' &&
                innerElement.text.toLowerCase().contains('day')) {
              var daySection = innerElement;
              var dayNumber = int.tryParse(
                      daySection.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                  1;
              print('  Processing Day $dayNumber');

              List<Exercise> exercises = [];
              var exerciseElement = daySection.nextElementSibling;
              while (exerciseElement != null &&
                  !exerciseElement.localName!.startsWith('h')) {
                if (exerciseElement.localName == 'ul') {
                  for (var li in exerciseElement.children) {
                    exercises.add(_parseExerciseDetails(li.text.trim()));
                  }
                } else if (exerciseElement.localName == 'p' &&
                    exerciseElement.text.trim().startsWith('*')) {
                  exercises.add(_parseExerciseDetails(
                      exerciseElement.text.trim().substring(1).trim()));
                }
                exerciseElement = exerciseElement.nextElementSibling;
              }
              days.add(Day(dayNumber: dayNumber, exercises: exercises));
            }
            currentElement = innerElement;
            innerElement = innerElement?.nextElementSibling;
          }
          weeks.add(Week(
              weekNumber: weekNumber,
              days: days,
              focus: focus,
              intensity: intensity));
        }
        currentElement = currentElement?.nextElementSibling;
      }

      Map<String, dynamic> metrics = {};
      var metricsSection = _findSectionByHeading(document, 'metrics');
      if (metricsSection != null) {
        var metricItems = metricsSection.querySelectorAll('li');
        print('\n=== Extracting Metrics ===');
        for (var item in metricItems) {
          var text = item.text.trim();
          if (text.contains(':')) {
            var parts = text.split(':');
            var key = parts[0].trim().toLowerCase().replaceAll(' ', '_');
            var value = parts[1].trim();
            metrics[key] = value;
            print('  $key: $value');
          }
        }
      }

      print('\n=== Workout Plan Parsing Complete ===');
      return WorkoutPlan(
        targetArea: targetArea,
        bodyType: bodyType,
        weeks: weeks,
        metrics: metrics,
        precautions: precautions,
        description: description,
      );
    } catch (e) {
      print('\n=== Error Parsing Workout Plan ===');
      print('Error: $e');
      return WorkoutPlan.empty();
    }
  }

  Exercise _parseExerciseDetails(String markdownExercise) {
    String name = 'Unknown Exercise';
    String description = '';
    int sets = 0;
    int reps = 0;
    String duration = 'N/A';
    String difficulty = 'Medium';
    List<String> equipment = [];
    List<String> instructions = [];

    final lines = markdownExercise.split('\n').map((e) => e.trim()).toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('Exercise')) {
        name = line.split(':').skip(1).join(':').trim();
        if (name.contains('Instructions')) {
          name = name.split('Instructions')[0].trim();
        }
      } else if (line.startsWith('Sets:')) {
        sets = int.tryParse(line.split(':')[1].trim()) ?? 0;
      } else if (line.startsWith('Reps:')) {
        reps = int.tryParse(line.split(':')[1].trim()) ?? 0;
      } else if (line.startsWith('Duration:')) {
        duration = line.split(':')[1].trim();
      } else if (line.startsWith('Difficulty:')) {
        difficulty = line.split(':')[1].trim();
      } else if (line.startsWith('Equipment:')) {
        equipment = line
            .split(':')
            .skip(1)
            .join(':')
            .trim()
            .split(', ')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (line.startsWith('Instructions:')) {
        instructions = line
            .split(':')
            .skip(1)
            .join(':')
            .trim()
            .split(', ')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return Exercise(
      name: name,
      description: description,
      sets: sets,
      reps: reps,
      duration: duration,
      difficulty: difficulty,
      equipment: equipment,
      instructions: instructions,
    );
  }

  dom.Element? _findSectionByHeading(
      dom.Document document, String headingText) {
    final h2Elements = document.querySelectorAll('h2');
    for (var h2 in h2Elements) {
      if (h2.text.toLowerCase().contains(headingText.toLowerCase())) {
        return h2;
      }
    }
    final h3Elements = document.querySelectorAll('h3');
    for (var h3 in h3Elements) {
      if (h3.text.toLowerCase().contains(headingText.toLowerCase())) {
        return h3;
      }
    }
    final h4Elements = document.querySelectorAll('h4');
    for (var h4 in h4Elements) {
      if (h4.text.toLowerCase().contains(headingText.toLowerCase())) {
        return h4;
      }
    }
    return null;
  }

  List<String> _extractListItems(dom.Element section) {
    List<String> items = [];
    var current = section.nextElementSibling;
    while (current != null && !current.localName!.startsWith('h')) {
      if (current.localName == 'ul') {
        for (var li in current.children) {
          items.add(li.text.trim());
        }
      } else if (current.localName == 'p') {
        items.add(current.text.trim());
      }
      current = current.nextElementSibling;
    }
    return items;
  }
}
