## What is this

An iOS app for tracking progress on reading books.

Motivation: using Goodreads for tracking books in progress is a cool idea, but the user experience
they've implemented is too cumbersome, and unlikely to ever improve. And new tokens for the
Goodreads API are not available anymore, so it can't be plugged-into directly. Other reading apps
on the App Store are often very childish/gamified, and often focused on social aspects than
tracking reading progress specifically.

### Screenshots

#### Homescreen

![homescreen.png](screenshots/homescreen.png)

#### Book progress

![book-progress.png](screenshots/book-progress.png)

## Development notes

After updating Riverpod code, the generators should be run with eg. `dart run build_runner watch`.

Consider looking at the [Flutter Cookbook](https://docs.flutter.dev/cookbook) for ideas.

### Updating the app icon

Have a PNG of the icon 1024x1024px.

Find the current
design [here on Canva](https://www.canva.com/design/DAGdUjxKLrc/cpdRXKwv_ZsDuiwb3pXkUQ/edit).

Overwrite the file at `assets/icon/app_icon.png` (as referenced by `flutter_launcher_icons` in
the `pubspec.yaml`).

Now execute

```shell
flutter pub get;
flutter pub run flutter_launcher_icons;
flutter clean;
```

### Updating app on the phone

This way we can run the app on the phone without tethering to the dev env.

* Start with `flutter build ios --release`
* In XCode open the "blue on white" version of the xcode file
* Open menu-bar `Product > Archive` (20sec)
* Click "Distribute App", for "Release Testing" (10sec)
* Click "Export" to e.g. Desktop (5sec)
* Connect (properly registered) iPhone to laptop
* Open "Apple Configurator" app on laptop
    * It will load iphone homescreen automatically (10sec)
* Open the directory that was exported to the Desktop
* Drag the `book_track.ipa` file onto the iphone homescreen (8sec)
* Then click replace (5sec)
* Wait for it to finish installing on the phone (5sec)
* Disconnect phone from laptop
