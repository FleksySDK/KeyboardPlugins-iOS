#  Integration guide

Create your own FleksyApp using the BaseFleksyApp.

## Overview

Creating a media content selection FleksyApp with the BaseFleksyApp is very straightforward. You just need to care about fetching the content for the BaseFleksyApp and implementing the custom action for when the user selects a media content. That's all.

In more technical terms, in order to create your own FleksyApp using the BaseFleksyApp you need to:
* Create your media content object type implementing the ``BaseContent`` protocol.
* Optionally create your category type implementing the ``BaseCategory`` protocol.
* Create your own subclass of ``BaseApp``.

Currently, the `BaseApp` only supports showing the following content types (see ``BaseMedia/ContentType-swift.enum``):
* Images.
* Videos.

Below we will illustrate this guide with the example of the `GiphyApp`, which is a FleksyApp built using the BaseFleksyApp. 

### The media content object

The first thing you need is a type that represents each media content item to be presented in the FleksyApp. For that, your media content type needs to implement the ``BaseContent`` protocol. 

Basically, each media item needs to have a unique identifier and needs to be mappable to a ``BaseMedia`` object. The ``BaseMedia`` struct contains all the information required for the ``BaseApp`` class to download and show the content of the media item. Note that the ``BaseMedia/contentType-swift.property`` is the value that determines the type of content presented to the user in the media carousel.

For example, the Giphy app uses the `GifContent`:

```swift
public struct GifContent: BaseContent {
    var gifURL: URL
    var thumbnailVideo: BaseMedia
    
    // BaseContent protocol conformance:

    public var viewMedia: BaseFleksyApp.BaseMedia { thumbnailVideo }
    public var id: String
}
```

This is how the media items are shown in a horizontally scrollable carousel:

![An image highlighting the horizontal carousel of media items.](MediaCarousel.png)

### The category object

You can **optionally** provide the user with an array of items that can be used, for example, for content filtering. This is called "category" by the `BaseFleksyApp`. These categories are shown as a selectable, scrollable list at the bottom of the FleksyApp.

> Note: You can opt out of the categories functionality by using the `Never` type, which already implements the ``BaseCategory`` protocol and tells the ``BaseApp`` to remove the category selection list from the FleksyApp.

Each category item needs a unique identifier and the user-facing name of the category.

The Giphy app uses the `GifsCategory` struct for this purpose and these categories are, in fact, shorcuts for trending searches.

```swift
public struct GifsCategory: BaseCategory {

    let query: String

    // BaseCategory protocol conformance:
    
    public let categoryName: String
    public var id: String { query }
}
```

This is how the categories are shown in a horizontally scrollable list:

![An image highlighting the horizontal list of categories.](CategoryList.png)

### Create your BaseApp subclass

Once you declared your media content and category types, you are ready to create the main class of your own FleksyApp. This class needs to be a subclass of ``BaseApp`` and should use the types defined before for the two generic types required by ``BaseApp``.

```swift
public class GiphyApp: BaseApp<GifContent, GifsCategory> {
    ...
}
```

Your ``BaseApp`` subclass must override the following set of methods that are the ones taking care of fetching the actual information to be shown. 

- ``BaseApp/getDefaultContentsFor(pagination:)``. This asynchronous method should provide the default contents for the FleksyApp for when the FleksyApp opens.
- ``BaseApp/getContentsFor(query:pagination:)``. This asynchronous method should provide the contents resulting of the user query. For example, the result contents of a search.
- ``BaseApp/getContentsFor(category:pagination:)``. This asynchronous method should provide the contents for a specific category. If you opted out of the categories functionality using the `Never` type, you do not need to override this method.
- ``BaseApp/getCategories()``. This asynchronous method should return the available categories selectable by the user. Returning an empty array hides the category selection list. In addition, If you opted out of the categories functionality using the `Never` type, you do not need to override this method.

### Implement custom behavior

There are some additional overridable methods declared in ``BaseApp`` that you can use to customize the behavior of your FleksyApp. 

- ``BaseApp/didSelectContent(_:)`` is the most important one. This method gets executed when the user taps on a content media cell. In the case of the Giphy app, it downloads the selected gif and puts it into the general clipboard  so that the user can later paste it wherever they need. 
- ``BaseApp/onAppIconAction()``. This is the method that gets called when the user taps on the Fleksy app icon button shown on the left of the in-keyboard search text field. ``BaseApp``'s implementation changes the view mode of the FleksyApp to `.fullCover`. You can override this method to provide custom logic for this event.
- ``BaseApp/getErrorMessageForError(_:)`` is used to let the user know when an error happens. ``BaseApp``'s implementation returns the default message for each error (see ``BaseError/defaultErrorMessage``). You can override this method in your ``BaseApp`` subclass to customize the error messages.

### Other public methods

Finally, the ``BaseApp`` provides some public methods that allow you to change the UI in different ways.

#### Programmatically selecting a Category

If your FleksyApp uses the categories functionality, your ``BaseApp`` subclass can call ``BaseApp/setSelectedCategory(_:)`` to visually select a category when it makes sense. 

For example, in the Giphy app, selecting the category "GOODNIGHT" is functionally the same as searching for the term "GOODNIGHT". Therefore, if the user performs a search with the query "Goodnight", the Giphy app programmatically selects the "GOODNIGHT" category for consistency.

![An image of the Giphy app showing the search term marching the selected category.](GiphyCategorySelection.png)

### Showing a message toast

The ``BaseApp`` also provides a set of methods to show/hide a toast with a custom message. This can be usefull when you want to provide user feedback from within your app:
- Use ``BaseApp/showToast(message:alignment:showLoader:animationDuration:delay:)`` or ``BaseApp/showToastAndWait(message:alignment:showLoader:animationDuration:delay:)`` to present the message.
- Use ``BaseApp/hideToast(animationDuration:delay:)`` or ``BaseApp/hideToastAndWait(animationDuration:delay:)`` to hide the message.

The Giphy uses these methods app presents a temporary toast message when the user selects a gif to let them know that the gif is copied and ready for them to paste. 

![An image of the Giphy app showing a toast message after the user has selected a gif.](GiphyAppToast.png)
