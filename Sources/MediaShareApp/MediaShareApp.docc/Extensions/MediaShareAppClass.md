#  ``MediaShareApp/MediaShareApp``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Initializer

- ``init(contentType:apiKey:sdkLicenseKey:)``

### Instance methods

- ``appIcon()``

### Static methods

- ``appId(forContentType:)``


###

> Important: Since ``MediaShareApp/MediaShareApp`` is a subclass of `BaseApp` and they are declared in different targets of the package, the methods it overrides need to be public. Do not call any of these methods since it could cause inderterminate behaviors.

- ``didSelectContent(_:)``

- ``getCategories()``

- ``getContentsFor(category:pagination:)``

- ``getContentsFor(query:pagination:)``

- ``getDefaultContentsFor(pagination:)``

- ``initialize(listener:configuration:)``

- ``onConfigurationChanged(_:)``
