# How to integrate MediaShareApp

Learn how to easily integrate the MediaShareApp into your custom keyboard extension powered by FleksySDK.

## Overview

To integrate the MediaShareApp in your FleksySDK-powered keyboard extension you will only need:
* The credentials for MediaShareApp.
* Chose a media type.
* Creating an instance of ``MediaShareApp``.  

### Obtain the credentials for the MediaShareApp

The credentials you will need to implement the MediaShareApp are:
* A MediaShare app API key. You can obtain it by writing an email to customer.support@fleksy.com indicating that you want an API key for the MediaShare app.
* The FleksySDK license key. You can obtain it from the [Fleksy Developers platform](https://developers.fleksy.com/).

### Chosing the media type

Currently, the MediaShareApp supports 3 types of contents (``MediaShareApp/ContentType``):
* Gifs. The user can select from a collection of gifs. When they select a gif from the collection, it will be copied to the pasteboard.
* Clips. The user can select from a collection of short video clips. When they select a clip from the collection, it will be copied to the pasteboard.
* Stickers. The user can select from a collection of animated stickers. When they select a sticker from the collection, it will be copied to the pasteboard.

### The MediaShareApp class

All you need to enable the MediaShareApp in your keyboard extension is to pass the KeyboardSDK a ``MediaShareApp`` instance in the `createConfiguration()` of your own `FKKeyboardViewController` subclass. To do this, initialize the  `AppsConfiguration` object including the ``MediaShareApp`` instance in the `keyboardApps` array parameter and then pass this `AppsConfiguration` object in the returned `KeyboardConfiguration` for the `apps` parameter.

To initialize the ``MediaShareApp`` instance, you will need:
* The MediaShare app API key.
* The FleksySDK license key.
* The type of media for the ``MediaShareApp``: gifs, clips or stickers.

```swift

override func createConfiguration() -> KeyboardConfiguration {

    let mediaShareApp = MediaShareApp(contentType: .gifs, // or .clips or .stickers 
                                      apiKey: "your-MediaShareApp-api-key",
                                      sdkLicenseKey: "your-FleksySDK-license-key") 
    let appsConfiguration = AppsConfiguration(keyboardApps: [mediaShareApp],
                                              showAppsInCarousel: true)

    return KeyboardConfiguration(panel: ...,
                                 capture: ...,
                                 style: ...,
                                 appearance: ...,
                                 typing: ...,
                                 specialKeys: ...,
                                 apps: appsConfiguration,
                                 license: ...,
                                 debug: ...)
}
```

After this, the user will be able to open the MediaShare app from the FleksyApps carousel that is accessed by pressing the action button on the left of the top bar of the keyboard.

### How to open the MediaShareApp programmatically

The app identifier of the MediaShareApp depends on the type of media content it displays (gifs, clips or stickers). To obtain the app identifier for a specific type of media you can use MediaShareApp's static method ``MediaShareApp/appId(forContentType:)``.
You can then open your MediaShareApp programmatically at any point in your code by with the `openApp(appId:)` method of `FKKeyboardViewController`. For example, for a MediaShareApp for clips, your custom subclass of `FKKeyboardViewController` could do:

```swift
self.openApp(appId: MediaShareApp.appId(forContentType: .clips)

```

Additionally, if you wanted to disable the apps carousel interface in your keyboard extension and let the user open the MediaShareApp directly when tapping the action button on the left of the top bar of the keyboard, you can do so following these steps:

1. Pass `false` for the `showAppsInCarousel` parameter of the `AppsConfiguration` initializer.
1. Override the `triggerOpenApp()` method in your subclass of `FKKeyboardViewController`.
1. Call `openApp(appId: MediaShareApp.appId(forContentType: <#content_type#>))` in the implentation of `triggerOpenApp()`.

```swift

override func createConfiguration() -> KeyboardConfiguration {

    let mediaShareApp = MediaShareApp(contentType: .gifs, // or .clips or .stickers 
                                      apiKey: "your-MediaShareApp-api-key",
                                      sdkLicenseKey: "your-FleksySDK-license-key") 
    let appsConfiguration = AppsConfiguration(keyboardApps: [mediaShareApp],
                                              showAppsInCarousel: true)

    return KeyboardConfiguration(panel: ...,
                                 capture: ...,
                                 style: ...,
                                 appearance: ...,
                                 typing: ...,
                                 specialKeys: ...,
                                 apps: appsConfiguration,
                                 license: ...,
                                 debug: ...)
}

override func triggerOpenApp() {
    openApp(appId: MediaShareApp.appId(forContentType: .gifs)) // or .clips or .stickers
}
```

