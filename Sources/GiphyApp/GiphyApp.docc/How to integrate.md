# How to integrate GiphyApp

Learn how to easily integrate the GiphyApp into your custom keyboard extension powered by FleksySDK.

## Overview

To integrate the GiphyApp in your FleksySDK-powered keyboard extension you will only need:
* A Giphy API key.
* Create a ``GiphyApp`` instance.  


### Obtain a Giphy API key

You can learn how to request a Giphy API Key [here](https://support.giphy.com/hc/en-us/articles/360020283431-Request-A-GIPHY-API-Key).

### The GiphyApp class

All you need to enable the GiphyApp in your keyboard extension is pass the KeyboardSDK a ``GiphyApp`` instance in the `createConfiguration()` of your own `FKKeyboardViewController` subclass. To do this, initialize the  `AppsConfiguration` object including the ``GiphyApp`` instance in the `keyboardApps` array parameter and then pass this `AppsConfiguration` object in the returned `KeyboardConfiguration` for the `apps` parameter. 

```swift

override func createConfiguration() -> KeyboardConfiguration {

    let giphyApp = GiphyApp(apiKey: "your-Giphy-api-key")
    let appsConfiguration = AppsConfiguration(keyboardApps: [giphyApp],
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

After this, the user will be able to access the Giphy app from the FleksyApps carousel that is accessed by pressing the action button on the left of the top bar of the keyboard.

### How to open the GiphyApp programmatically

You can open the GiphyApp programmatically at any point in your code by with the `openApp(appId:)` method of `FKKeyboardViewController`. For example, from your custom subclass of `FKKeyboardViewController` you could do:

```swift
self.openApp(appId: GiphyApp.appId)

```

Additionally, if you wanted to disable the apps carousel interface in your keyboard extension and let the user open the GiphyApp directly when tapping the action button on the left of the top bar of the keyboard, you can do so following these steps:

1. Pass `false` for the `showAppsInCarousel` parameter of the `AppsConfiguration` initializer.
1. Override the `triggerOpenApp()` method in your subclass of `FKKeyboardViewController`.
1. Call `openApp(appId: GiphyApp.appId)` in the implentation of `triggerOpenApp()`.

```swift

override func createConfiguration() -> KeyboardConfiguration {

    let giphyApp = GiphyApp(apiKey: "your-Giphy-api-key")
    let appsConfiguration = AppsConfiguration(keyboardApps: [giphyApp],
                                              showAppsInCarousel: false)

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
    openApp(appId: GiphyApp.appId)
}
```
