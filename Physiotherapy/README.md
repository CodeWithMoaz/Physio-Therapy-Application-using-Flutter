# Athlete Recovery

Athlete Recovery is a Flutter mobile app for personalized sports injury
rehabilitation. It helps patients discover physiotherapy programs, follow
video-guided exercises, track recovery progress, connect with doctors, and use
AI-assisted medical report analysis and workout-plan generation.

The application supports rehabilitation for the knee, ankle, shoulder, and
lower back. Its Firebase-backed data model supports patients, doctors, admins,
programs, exercises, and AI-generated programs.

> This application provides rehabilitation guidance and is not a replacement
> for diagnosis or treatment from a qualified medical professional.

<img width="1538" height="828" alt="{B200E19F-3E13-4028-86F5-67960B2FC25A}" src="https://github.com/user-attachments/assets/0dc33bb2-9634-414f-b0d2-a82825e06452" />

## Features

### Patient experience

- Email and password sign-up, login, logout, and password reset.
- Guided onboarding and patient profile setup.
- Browse physiotherapist-managed rehabilitation programs.
- Filter programs by injury type, severity, age group, and search text.
- View program duration, severity, pricing, doctor details, and descriptions.
- Enroll in a program and track enrolled programs and completion progress.
- View a daily exercise plan organized by week and day.
- Watch exercise videos and view exercise instructions, sets, repetitions, and
  descriptions.
- Mark clinic visits and distinguish clinic days from home exercise days.
- Choose an AI rehabilitation path for a knee, ankle, shoulder, or lower-back
  condition.
- Generate a personalized workout plan using age, gender, height, weight,
  target injury area, and body type.
- Complete AI workouts with animated progress, exercise navigation, and video
  playback.
- Upload a medical report image, extract its text, and request an AI injury
  classification with symptoms, supporting evidence, description, and
  treatment recommendations.
- View and update profile information and review booking history where data is
  available.

### Doctor experience

- Sign in using a doctor account.
- View managed programs and patient plan counts.
- Create, edit, and filter rehabilitation programs.
- Manage exercises assigned to patient plans.
- Review patient progress, last visits, clinic days, and daily exercises.
- Add or remove exercises from a patient's plan and update clinic-day status.

### Admin experience

- View pending, approved, and rejected doctor counts.
- Review pending doctor applications.
- Inspect doctor certificates and profile information.
- Approve or reject doctor accounts.

## Main User Flows

### Patient rehabilitation flow

1. Start the app and complete onboarding.
2. Create an account or log in.
3. Choose the rehabilitation route.
4. Browse a doctor-managed program or an AI program.
5. Enroll in a doctor-managed program, or provide profile information for AI
   plan generation.
6. Select a week and day, then follow the exercise list and videos.
7. Continue from the recorded progress on the next visit.

### Medical report flow

1. Select a report image from the device gallery.
2. Send it to the configured Tesseract-based text-extraction service.
3. Extract and review report fields such as findings, impression, diagnosis,
   injury location, severity, recommendations, and physician information.
4. Send the relevant findings, impression, diagnosis, and injury details to
   OpenRouter for structured AI injury diagnosis/classification.
5. Review the generated injury classification, symptoms, supporting evidence,
   description, and treatment recommendations.

## Technology Stack

- [Flutter](https://flutter.dev/) and Dart
- Firebase Core
- Firebase Authentication for account access
- Cloud Firestore for users, doctors, programs, exercises, and progress
- Firebase Storage for stored media where configured
- OpenRouter API for injury diagnosis/classification and personalized workout
  plan generation
- FastAPI, Tesseract OCR, Pillow, OpenCV, and Python regular expressions for
  medical report text extraction and field parsing
- `video_player` for exercise demonstrations
- `image_picker` and `camera` for image capture and selection
- Lottie, Flutter Animate, and Flutter Staggered Animations for motion and
  loading states
- Poppins font and local image, video, HTML, and animation assets

## Requirements

- Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`
- Android Studio and an Android SDK for Android development, or Xcode for iOS
- A configured Firebase project
- An OpenRouter API key for AI features
- A running text-extraction API for medical report processing

Check the installed toolchain with:

```bash
flutter doctor
```

## Installation

Clone the repository and install the Flutter dependencies:

```bash
git clone <repository-url>
cd Physiotherapy
flutter pub get
```

Run the application on a connected device or emulator:

```bash
flutter devices
flutter run
```

For a release build:

```bash
flutter build apk --release
```

Use `flutter build ipa --release` on macOS for an iOS archive. iOS builds
require the normal Apple signing and provisioning configuration.

## Text-Extraction Service Setup

The Flutter app depends on the Python service in
`models/text_extraction/text_extraction.py` when processing medical report
images. The service requires Python, Tesseract OCR, and the packages listed in
`models/text_extraction/requirements.txt`.

From the repository root, create and activate a virtual environment, install
the dependencies, and start the service:

```bash
cd models/text_extraction
python -m venv .venv
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
python -m pip install -r requirements.txt
uvicorn text_extraction:app --host 0.0.0.0 --port 8000
```

Install Tesseract OCR separately and make sure its executable path matches the
configuration in `text_extraction.py`. The current Windows configuration is
`C:\Program Files\Tesseract-OCR\tesseract.exe`. Update that path for other
machines. Android emulators reach a service running on the host through
`10.0.2.2`; physical devices and iOS simulators need a reachable host address
or deployed HTTPS endpoint.

## Medical Report Diagnosis and Text Extraction

Medical report analysis is implemented as a two-stage pipeline:

1. The Flutter app uploads a report image to the Python service at
   `POST /extract-text/`.
2. The extraction service reads the image with Pillow, preprocesses a copy
   with OpenCV, and runs Tesseract OCR in English.
3. The service compares the raw and preprocessed OCR results and keeps the
   longer result.
4. Python regular expressions parse the extracted text into structured fields,
   including patient details, technique, findings, impression, diagnosis,
   recommendations, injury location, injury severity, procedure, conclusion,
   and observations.
5. The Flutter app cleans the returned data and sends the clinically relevant
   fields to OpenRouter.
6. OpenRouter returns a structured AI injury diagnosis/classification containing
   an injury name with degree, common symptoms, supporting evidence, a
   description, and treatment recommendations.

The text-extraction service source is located at
`models/text_extraction/text_extraction.py`. It exposes a FastAPI application
and currently uses a local Windows Tesseract installation configured at:

```text
C:\Program Files\Tesseract-OCR\tesseract.exe
```

To run the service locally, install Python dependencies and Tesseract OCR,
then start the FastAPI application from the text-extraction directory. The
Flutter app expects the service to be reachable at
`http://10.0.2.2:8000/extract-text/` when running on an Android emulator.
Update the URL in the Flutter medical-report screen for a physical device,
iOS simulator, or production deployment.

This AI feature is an aid for interpreting report content, not a medical
diagnosis from a licensed clinician. Users should confirm results with a
qualified healthcare professional.

## Firebase Configuration

The project initializes Firebase in `lib/main.dart` using
`lib/firebase_options.dart`. Before running the application with a different
Firebase project:

1. Create or select a Firebase project.
2. Enable Email/Password authentication.
3. Create a Cloud Firestore database.
4. Configure the Android and iOS apps with their correct package and bundle
   identifiers.
5. Run FlutterFire configuration and regenerate `lib/firebase_options.dart`.
6. Apply Firestore security rules appropriate for your deployment.

The application reads and writes these Firestore collections:

| Collection    | Purpose                                                                    |
| ------------- | -------------------------------------------------------------------------- |
| `users`       | Patient profile data, enrollment records, plans, progress, and clinic days |
| `doctors`     | Doctor profiles, verification status, and managed program IDs              |
| `programs`    | Doctor-managed rehabilitation programs                                     |
| `exercises`   | Exercise metadata, media paths, instructions, and program links            |
| `ai_programs` | AI rehabilitation program catalog entries                                  |

Do not copy production credentials or private API keys into the repository.
Firebase client configuration is generated for the app, but access must still
be protected by Firebase Authentication and Firestore security rules.

## AI and API Configuration

Create a `.env` file in the project root:

```dotenv
API_KEY=your_openrouter_api_key
```

The app loads `.env` at startup. The key is used by the OpenRouter integration
at `https://openrouter.ai/api/v1/chat/completions` for:

- Medical report injury diagnosis/classification.
- Structured personalized workout-plan generation.

The medical report workflow currently sends images to this endpoint:

```text
http://10.0.2.2:8000/extract-text/
```

`10.0.2.2` resolves to the host machine from an Android emulator. For a real
device, iOS simulator, or production deployment, update the endpoint to a
reachable HTTPS service. The service should accept a multipart `file` upload
and return the extracted report text/data expected by the app.

The `.env` file is included as a Flutter asset, so keep it out of version
control. A local development setup can use a `.gitignore` entry such as:

```gitignore
.env
```

## Assets

The app declares these asset directories in `pubspec.yaml`:

- `assets/img/` for injury, profile, navigation, and UI images
- `assets/videos/` for exercise demonstration videos
- `assets/html/` for local HTML content grouped by injury area
- `assets/font/` for the Poppins font family
- `.env` for local API configuration

When adding an exercise or program that references local media, ensure the
path matches the declared asset structure and uses forward slashes.

## Project Structure

```text
lib/
├── api_service/       OpenRouter and workout-plan API integrations
├── common/            Colors and shared application utilities
├── common_widget/     Reusable buttons and widgets
├── models/            Firestore and workout-plan data models
├── services/          Authentication and Firestore services
├── view/
│   ├── login/         Sign-up, login, and profile completion
│   ├── home/          Patient, doctor, and admin home screens
│   ├── rehabilitation/ Programs, plans, exercises, and workouts
│   ├── medical_report_explaination/ Report extraction and classification
│   ├── on_boarding/   Initial app onboarding
│   └── profile/       Profile and history screens
└── main.dart          App entry point and Firebase initialization
```

Generated directories such as `build/` should not be committed.

## Testing and Analysis

Run static analysis and the Flutter test suite with:

```bash
flutter analyze
flutter test
```

The current widget test is still the default Flutter counter smoke test and
does not yet cover the rehabilitation, Firebase, or AI flows. Tests that
exercise Firebase and external APIs should use mocks or a dedicated test
Firebase project.

## Known Development Notes

- Firebase initialization is required at startup, including for the default
  widget test unless Firebase is mocked or the app entry point is isolated.
- Linux Firebase options are not configured in `lib/firebase_options.dart`.
- AI features require both a valid OpenRouter key and network access.
- Medical report processing requires the separate text-extraction service.
- Exercise and program content is loaded from Firestore, while many default
  images and videos are bundled locally.
- The application is primarily intended for Android and iOS mobile use; web,
  Windows, and macOS configuration is present but should be validated before
  release.

## Project Documents

- [Project Presentation](../Project%20Presentation/Moaz%20Presentation.pptx)
- [Project Report](../Project%20Report/Moaz%20Report.docx)

The top-level `Project Presentation/` and `Project Report/` folders contain the
presentation and written report independently from the Flutter project folder.

## Author

Developed by [CodeWithMoaz](https://github.com/CodeWithMoaz).

## Publishing To GitHub

The repository should contain the Flutter source, platform folders, assets,
Python text-extraction source, dependency files, `pubspec.yaml`,
`pubspec.lock`, and this README. Do not upload `.env`, Firebase private
credentials, `android/local.properties`, generated build output, or virtual
environment folders.

To publish this project to the
`CodeWithMoaz/Physio-Therapy-Application-using-Flutter` repository:

```bash
git init
git add .
git commit -m "Initial project upload"
git branch -M main
git remote add origin https://github.com/CodeWithMoaz/Physio-Therapy-Application-using-Flutter.git
git push -u origin main
```

If the remote already contains a README or other commit, pull it first and
resolve any merge conflicts before pushing. GitHub authentication may require
a browser sign-in, SSH remote, or personal access token.
