#  Localize the MediaShareApp

Get the list of strings you need to localize in order to adapt the MediaShare app in your keyboard extension to any language you want.

## Overview

The MediaShare app shows certain strings under some circumstances, for example, the search button hint or if an error occurs when contacting the MediaShareApp api. And it is a good practice to localize these strings.

![A couple of images showing the MediaShareApp in action.](MediaShareLocalization.png)

### Strings to localize

Here is an exhaustive list of all the localizable strings in the MediaShareApp, ready to be included in your `Localizable.strings` files. The strings on the right-hand side are the localized strings for the development locale.

```swift

// The user-facing error message for the lack of internet connection.
"BaseApp.Error.NoConnection" = "<#There is no internet connection.#>";

// The user-facing error message for a request that timed out
"BaseApp.Error.Timeout" = "<#Request timed out.#>";

// The user-facing error message for a bad URL error
"BaseApp.Error.BadURL" = "<#Error: bad URL.#>";

// The user-facing error message for a bad server response.
"BaseApp.Error.BadServerResponse" = "<#BaseApp.Error.BadServerResponse#>";

// The user-facing error message for a cancelled request
"BaseApp.Error.RequestCancelled" = "<#The request was cancelled#>";

// A user-facing error message for an invalid HTTP status code. The parameter is the HTTP status code of the request that failed
"BaseApp.Error.InvalidHTTPStatusCodeFormat" = "<#Error: invalid status code %d.#>";

// The user-facing error message for a generic error"
"BaseApp.Error.Other" = "<#An unknown error occurred.#>";

// Gifs MediaShareApp

// The title of Trending category for the gifs MediaShareApp
"MediaShare.Category.Trending.gifs" = "<#Trending#>";

// The placeholder of the keyboard textfield for gifs
"MediaShare.SearchPlaceholder.gifs" = "<#Search for gifs...#>";

// The title of the search button for gifs in full cover mode
"MediaShare.SearchButtonText.gifs" = "<#Search for gifs...#>";

// The text to show in the toast while the gif selected by the user is being downloaded
"MediaShare.Toast.Downloading.gifs" = "<#Downloading#>";

// The text to show in the toast once the selected gif has completed downloading, is copied to the clipboard and ready to be pasted in applications
"MediaShare.Toast.CopiedAndReady.gifs" = "<#Copied and ready to paste!#>";

// The text shown when the user taps a gif but its download fails
"MediaShare.Error.download.gifs" = "<#The gif couldn't download#>";

// Clips MediaShareApp

// The title of Trending category for the clips MediaShareApp
"MediaShare.Category.Trending.clips" = "<#Trending#>";

// The placeholder of the keyboard textfield for clips
"MediaShare.SearchPlaceholder.clips" = "<#Search for clips...#>";

// The title of the search button for clips in full cover mode
"MediaShare.SearchButtonText.clips" = "<#Search for clips...#>";

// The text to show in the toast while the clip selected by the user is being downloaded
"MediaShare.Toast.Downloading.clips" = "<#Downloading#>";

// The text to show in the toast once the selected clip has completed downloading, is copied to the clipboard and ready to be pasted in applications
"MediaShare.Toast.CopiedAndReady.clips" = "<#Copied and ready to paste!#>";

// The text shown when the user taps a clip but its download fails
"MediaShare.Error.download.clips" = "<#The clip couldn't download#>";

// Stickers MediaShareApp

// The title of Trending category for the stickers MediaShareApp
"MediaShare.Category.Trending.stickers" = "<#Trending#>";

// The placeholder of the keyboard textfield for stickers
"MediaShare.SearchPlaceholder.stickers" = "<#Search for stickers...#>";

// The title of the search button for stickers in full cover mode
"MediaShare.SearchButtonText.stickers" = "<#Search for stickers...#>";

// The text to show in the toast while the sticker selected by the user is being downloaded
"MediaShare.Toast.Downloading.stickers" = "<#Downloading#>";

// The text to show in the toast once the selected sticker has completed downloading, is copied to the clipboard and ready to be pasted in applications
"MediaShare.Toast.CopiedAndReady.stickers" = "<#Copied and ready to paste!#>";

// The text shown when the user taps a sticker but its download fails
"MediaShare.Error.download.stickers" = "<#The sticker couldn't download#>";
```
