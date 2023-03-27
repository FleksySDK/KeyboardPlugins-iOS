#  Localize the GiphyApp

Get the list of strings you need to localize in order to adapt the Giphy app in your keyboard extension to any language you want.

## Overview

The Giphy app shows certain strings under some circumstances, for example, the search button hint or if an error occurs when contacting the Giphy api. And it is a good practice to localize these strings.

![A couple of images showing the GiphyApp with texts in English.](GiphyLocalization.png)

### Strings to localize

Here is an exhaustive list of all the localizable strings in the GiphyApp, ready to be included in your `Localizable.strings` files. The strings on the right-hand side are the localized strings for the development locale.

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

// The title of Trending category
"Giphy.Category.Trending" = "<#Trending#>";

// The title of the search button in full cover mode
"Giphy.SearchButtonText" = "<#Search on Giphy#>";

// The placeholder of the keyboard textfield
"Giphy.SearchPlaceholder" = "<#Search for gifs...#>";

// The text to show in the toast while the gif selected by the user is being downloaded
"Giphy.Toast.Downloading" = "<#Downloading#>";

// The text to show in the toast once the selected gif has completed downloading, is copied to the clipboard and ready to be pasted in applications
"Giphy.Toast.CopiedAndReady" = "<#Copied and ready to paste!#>";

// Represents an error or information about the absence of gifs shown 
"Giphy.Error.NoGifs" = "<#Currently there are no gifs available.#>";

// The text shown when the user taps a gif but the gif download fails
"Giphy.Error.download" = "<#The gif couldn't download#>";
```
