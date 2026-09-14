import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:physiotherapy/api_service/injury_classification.dart';

class OpenRouterService {
  final String apiKey;
  final String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  OpenRouterService({required this.apiKey});

  Future<InjuryClassification> classifyInjury(
      Map<String, dynamic> extractedData) async {
    String reportContent = '';

    if (extractedData['Findings'] != null &&
        extractedData['Findings']!.isNotEmpty) {
      reportContent += 'Findings: ${extractedData['Findings']}\n';
    }

    if (extractedData['Impression'] != null &&
        extractedData['Impression']!.isNotEmpty) {
      reportContent += 'Impression: ${extractedData['Impression']}\n';
    }

    if (extractedData['Diagnosis'] != null &&
        extractedData['Diagnosis']!.isNotEmpty) {
      reportContent += 'Diagnosis: ${extractedData['Diagnosis']}\n';
    }

    if (extractedData['Injury Location'] != null &&
        extractedData['Injury Location']!.isNotEmpty) {
      reportContent += 'Injury Location: ${extractedData['Injury Location']}\n';
    }

    if (extractedData['Injury Severity'] != null &&
        extractedData['Injury Severity']!.isNotEmpty) {
      reportContent += 'Injury Severity: ${extractedData['Injury Severity']}\n';
    }

    if (reportContent.trim().isEmpty) {
      print('Error: No relevant data extracted from the report to analyze');
      return InjuryClassification.empty();
    }

    final prompt = '''
Analyze the following medical report data and provide a VERY STRUCTURED analysis with the following format:

# [INJURY NAME WITH DEGREE]
IMPORTANT: You MUST ALWAYS include the degree (1st Degree, 2nd Degree, or 3rd Degree) in the injury name. For example:
- "ACL Partial Tear (2nd Degree)"
- "Rotator Cuff Strain (1st Degree)"
- "Hamstring Tear (3rd Degree)"
If the degree is not explicitly mentioned in the report, make an educated assessment based on the severity described.

## Common Symptoms
* [symptom 1]
* [symptom 2]
* [symptom 3]

## Supporting Evidence
* [evidence from report 1]
* [evidence from report 2]

## Description
[2-3 sentences describing the injury, its causes, and general information]

## Treatment Recommendations
* [recommendation 1]
* [recommendation 2]
* [recommendation 3]

IMPORTANT: 
1. The injury name MUST ALWAYS include the degree (1st, 2nd, or 3rd Degree)
2. Strictly follow this format with these exact section headings
3. Use bullet points for lists
4. If the degree is not explicitly mentioned, infer it from the severity described in the report

Medical Report Data:
$reportContent
''';

    try {
      print(
          'Making OpenRouter API request with API key length: ${apiKey.length}');

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
                  'You are a medical assistant specialized in analyzing medical reports and providing injury classifications. Format your responses in markdown with the injury name and degree as the title (H1), followed by common symptoms for this injury, then the specific evidence from the report that supports this classification, followed by a brief description and treatment recommendations.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      );

      print('OpenRouter API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('OpenRouter API JSON response: ${json.encode(jsonResponse)}');

        if (jsonResponse['choices'] == null ||
            jsonResponse['choices'].isEmpty) {
          print('Error: API returned empty choices array');
          return InjuryClassification.empty();
        }

        if (jsonResponse['choices'][0]['message'] == null ||
            jsonResponse['choices'][0]['message']['content'] == null) {
          print('Error: API response missing message content');
          return InjuryClassification.empty();
        }

        final aiResponse = jsonResponse['choices'][0]['message']['content'];

        print("Raw AI Response: $aiResponse");

        if (aiResponse == null || aiResponse.toString().trim().isEmpty) {
          print('Error: Empty AI response');
          return InjuryClassification.empty();
        }

        final parsedResponse = _parseMarkdownResponse(aiResponse);
        return InjuryClassification.fromMap(parsedResponse);
      } else {
        print('API Error: ${response.statusCode} ${response.body}');
        return InjuryClassification.empty();
      }
    } catch (e) {
      print('Error connecting to OpenRouter API: $e');
      return InjuryClassification.empty();
    }
  }

  Map<String, dynamic> _parseMarkdownResponse(String markdownResponse) {
    Map<String, dynamic> result = {
      'injury_name': 'Unknown Injury',
      'description': 'No description available.',
      'symptoms': <String>[],
      'supporting_evidence': <String>[],
      'recommendations': <String>[],
    };

    try {
      String htmlContent = md.markdownToHtml(markdownResponse);

      var document = html_parser.parse(htmlContent);

      var headings = document.querySelectorAll('h1');
      if (headings.isNotEmpty) {
        result['injury_name'] = headings.first.text.trim();
      } else {
        var altHeadings = document.querySelectorAll('h2, strong');
        if (altHeadings.isNotEmpty) {
          result['injury_name'] = altHeadings.first.text.trim();
        }
      }

      var symptomSection = _findSectionByHeading(document, 'symptoms');
      if (symptomSection != null) {
        result['symptoms'] = _extractListItems(symptomSection);
      }

      var evidenceSection = _findSectionByHeading(document, 'findings') ??
          _findSectionByHeading(document, 'evidence') ??
          _findSectionByHeading(document, 'support');
      if (evidenceSection != null) {
        result['supporting_evidence'] = _extractListItems(evidenceSection);
      }

      var descriptionSection = _findSectionByHeading(document, 'description');
      if (descriptionSection != null) {
        var paragraphs = descriptionSection.querySelectorAll('p');
        if (paragraphs.isNotEmpty) {
          result['description'] = paragraphs.first.text.trim();
        }
      } else {
        var paragraphs = document.querySelectorAll('p');
        if (paragraphs.isNotEmpty) {
          result['description'] = paragraphs.first.text.trim();
        }
      }

      var recSection = _findSectionByHeading(document, 'recommendations') ??
          _findSectionByHeading(document, 'treatment');
      if (recSection != null) {
        result['recommendations'] = _extractListItems(recSection);
      }
    } catch (e) {
      print('Error parsing markdown response: $e');
      return _parseAIResponse(markdownResponse);
    }

    return result;
  }

  dom.Element? _findSectionByHeading(
      dom.Document document, String headingText) {
    var headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');

    for (int i = 0; i < headings.length; i++) {
      if (headings[i].text.toLowerCase().contains(headingText.toLowerCase())) {
        var sectionElement = dom.Element.tag('div');

        var currentElement = headings[i].nextElementSibling;

        while (currentElement != null &&
            !currentElement.localName!.startsWith('h')) {
          sectionElement.children.add(currentElement.clone(true));
          currentElement = currentElement.nextElementSibling;
        }

        return sectionElement;
      }
    }
    return null;
  }

  List<String> _extractListItems(dom.Element section) {
    var items = <String>[];

    var listItems = section.querySelectorAll('li');
    for (var item in listItems) {
      var text = item.text.trim();
      if (text.isNotEmpty) {
        items.add(text);
      }
    }

    if (items.isEmpty) {
      var paragraphs = section.querySelectorAll('p');
      for (var p in paragraphs) {
        var text = p.text.trim();
        if (text.startsWith('•') ||
            text.startsWith('-') ||
            text.startsWith('*')) {
          text = text.substring(1).trim();
          if (text.isNotEmpty) {
            items.add(text);
          }
        } else if (text.isNotEmpty) {
          items.add(text);
        }
      }
    }

    return items;
  }

  Map<String, dynamic> _parseAIResponse(String aiResponse) {
    Map<String, dynamic> result = {
      'injury_name': 'Unknown Injury',
      'description': 'No description available.',
      'symptoms': <String>[],
      'supporting_evidence': <String>[],
      'recommendations': <String>[],
    };

    try {
      final nameMatch =
          RegExp(r'#\s+([^\n]+)', caseSensitive: false).firstMatch(aiResponse);
      if (nameMatch != null) {
        result['injury_name'] = nameMatch.group(1)?.trim() ?? 'Unknown Injury';
      } else {
        final altNameMatch = RegExp(
                r'(?:^|\n)([^:\n]+(?:(?:\s\d+(?:st|nd|rd|th))?\s?(?:Degree|Grade))?)',
                caseSensitive: false)
            .firstMatch(aiResponse);
        if (altNameMatch != null) {
          result['injury_name'] =
              altNameMatch.group(1)?.trim() ?? 'Unknown Injury';
        }
      }

      final symptoms = <String>[];
      if (aiResponse.contains('Symptoms')) {
        final symptomsSplit =
            aiResponse.split(RegExp(r'Symptoms:?|Common Symptoms:?'));
        if (symptomsSplit.length > 1) {
          final symptomsSection =
              symptomsSplit[1].split(RegExp(r'\n##|\n#'))[0];
          final symptomMatches =
              RegExp(r'(?:^|\n)[•\-*]\s*([^\n]+)', caseSensitive: false)
                  .allMatches(symptomsSection);
          for (var match in symptomMatches) {
            if (match.group(1) != null) {
              symptoms.add(match.group(1)!.trim());
            }
          }
        }
      }
      result['symptoms'] = symptoms;

      final evidence = <String>[];
      if (aiResponse.contains('Findings') ||
          aiResponse.contains('Evidence') ||
          aiResponse.contains('Supporting')) {
        final evidenceSplit = aiResponse
            .split(RegExp(r'Findings:?|Evidence:?|Supporting Evidence:?'));
        if (evidenceSplit.length > 1) {
          final evidenceSection =
              evidenceSplit[1].split(RegExp(r'\n##|\n#'))[0];
          final evidenceMatches =
              RegExp(r'(?:^|\n)[•\-*]\s*([^\n]+)', caseSensitive: false)
                  .allMatches(evidenceSection);
          for (var match in evidenceMatches) {
            if (match.group(1) != null) {
              evidence.add(match.group(1)!.trim());
            }
          }
        }
      }
      result['supporting_evidence'] = evidence;

      final descMatch = RegExp(
              r'(?:Description:?\s*|##\s*Description\s*\n)([^\n•\-*#]+)',
              caseSensitive: false)
          .firstMatch(aiResponse);
      if (descMatch != null) {
        result['description'] = descMatch.group(1)?.trim() ?? '';
      } else {
        final altDescMatch =
            RegExp(r'#[^#\n]+\n+([^\n•\-*#]+)', caseSensitive: false)
                .firstMatch(aiResponse);
        if (altDescMatch != null) {
          result['description'] = altDescMatch.group(1)?.trim() ?? '';
        }
      }

      final recommendations = <String>[];
      if (aiResponse.contains('Recommendation') ||
          aiResponse.contains('Treatment')) {
        final recommendationSplit =
            aiResponse.split(RegExp(r'Recommendations:?|Treatment:?'));
        if (recommendationSplit.length > 1) {
          final recommendationSection = recommendationSplit[1];
          final recommendationMatches =
              RegExp(r'(?:^|\n)[•\-*]\s*([^\n]+)', caseSensitive: false)
                  .allMatches(recommendationSection);
          for (var match in recommendationMatches) {
            if (match.group(1) != null) {
              recommendations.add(match.group(1)!.trim());
            }
          }
        }
      }
      result['recommendations'] = recommendations;
    } catch (e) {
      print('Error parsing AI response: $e');
    }

    return result;
  }
}
