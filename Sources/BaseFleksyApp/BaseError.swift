//  BaseError.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import Foundation

/// The type of errors used by the ``BaseApp``.
public enum BaseError: Error {
    
    /// No internet connection error.
    case noConnection
    
    /// Request timed out error.
    case timeout
    
    /// When receiving the error `URLError.Code.badURL`.
    case badURL
    
    /// The task was cancelled.
    case cancelled
    
    /// The response's HTTP status code was considered invalid.
    case invalidHTTPStatusCode(Int)
    
    /// When receiving the error `URLError.Code.badServerResponse`.
    case badServerResponse
    
    /// Generic, fallback error for when the error can't be represented by any of the other cases. Contains the underlying `Error` as associated value.
    case other(Error?)
    
    /// A localized user-facing error message.
    ///
    /// The default implementation of ``BaseApp/getErrorMessageForError(_:)`` uses this property of ``BaseError`` as the user-facing text. Therefore, make sure you include the localization of all the error strings (see ``BaseConstants/LocalizedStrings`` for the strings that need to be localized).
    public var defaultErrorMessage: String {
        switch self {
        case .noConnection:
            return BaseConstants.LocalizedStrings.noConnectionError
        case .timeout:
            return BaseConstants.LocalizedStrings.timeoutError
        case .badURL:
            return BaseConstants.LocalizedStrings.badURLError
        case .cancelled:
            return BaseConstants.LocalizedStrings.requestCancelledError
        case .badServerResponse:
            return BaseConstants.LocalizedStrings.badServerResponseError
        case .invalidHTTPStatusCode(let statusCode):
            return BaseConstants.LocalizedStrings.invalidHTTPStatusCodeError(statusCode)
        case .other:
            return BaseConstants.LocalizedStrings.otherError
        }
    }
}
