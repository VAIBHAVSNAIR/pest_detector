# PestGuard

PestGuard is a Flutter app for preparing crop photos for pest review. It includes
a crop-monitoring dashboard, camera and gallery image selection, scan guidance,
an activity-history view, and app settings.

## Run locally

```shell
flutter pub get
flutter run
```

Run the automated checks with:

```shell
flutter analyze
flutter test
```

## Current capabilities

- Select a crop photo from the gallery or take a new photo.
- Preview the selected image and check that it can be read.
- Browse the dashboard, scan workspace, history, and settings.
- Use the matching PestGuard display name and theme across app platforms.

AI pest identification and scan-history persistence are not implemented yet.
The app clearly labels AI analysis as unavailable until a model service is
connected; it does not display placeholder detection results.

## Store release checklist

Before publishing, connect and test the pest-detection service, implement
persistent scan history, configure a production application identifier and
release signing, and provide store listing assets and privacy information.
