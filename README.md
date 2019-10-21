# Patient Data Manager

There is currently one setup part that has to be done before the app will work. You will need to copy `Settings-Example.plist` in `pdm-ui` to `Settings.plist` and fill in the missing fields. Otherwise the application will immediately fail on launch, because the settings are loaded from that plist.

## Pilot Branch

This is a simplified variant that removes the health data visualization views to create a simpler "upload only" version.