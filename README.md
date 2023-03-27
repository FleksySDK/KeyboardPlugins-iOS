# About 🤔

FleksyApps serve as plugins for the Fleksy keyboard. 
While developing a keyboard might consume some time, even when utilizing our [FleksySDK](https://github.com/FleksySDK/fleksy), FleksyApps are designed to reduce that time. This is a way to provide your own personalized feature on top of the Fleksy keyboard.


# FleksyApps for iOS 🔌

This repository contains a collection of iOS FleksyApps: add-ons for keyboard extensions built with the iOS [Fleksy Keyboard SDK](https://docs.fleksy.com/keyboard-sdk/)

It includes the `BaseApp` template that makes the process of creating certain style of FleksyApps a lot easier and faster.
It also contains some ready-to-use apps to add directly to your keyboard extension:
* [GiphyApp](Sources/GiphyApp/): A FleksyApp powered by Giphy that allows the user to search and copy gifs.

# Installation

You can use any of the FleksyApps in this package with the Swift Package Manager:
```
https://github.com/FleksySDK/fleksyapps-iOS
```
Remember: in order to use the FleksyApps in your keyboard extension you need to add the `FleksyApps` framework to your keyboard extension target:

![Frameworks and Libraries section of keyboard target in Xcode including the FleksyApps framework](https://user-images.githubusercontent.com/95276123/226828607-aa07ac0b-f9d1-4c6e-8497-8cafb7660299.png)


If you want to make use of the `BaseFleksyApp` to create your own FleksyApps, you can add the FleksyApps package as a dependency by adding it to the `dependencies` value of your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/FleksySDK/fleksyapps-iOS.git", .upToNextMajor(from: "1.0.0"))
]
```

# Requirements

* This package requires a minimum deployment version of iOS 13.
* This package requires Xcode 14 or higher (Swift 5.7+).


# How to get help? 🙋

Any question that you might have, please post it directly into the [Github Discussion Forum](https://github.com/FleksySDK/fleksyapps-iOS/discussions).

Business related questions, please, go to our [developer portal](https://developers.fleksy.com), we will assist you as soon as possible.

