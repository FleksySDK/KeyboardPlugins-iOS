//  BaseConstants.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit

/// Constants used on a base app.
public enum BaseConstants {
    public enum Images {
        /// A question mark.
        ///
        /// The default app icon on the carousel if none is provided.
        public static var defaultAppIcon: UIImage? {
            if #available(iOS 15, *) {
                return UIImage(systemName: "questionmark.app.fill")?.withRenderingMode(.alwaysTemplate)
            } else {
                return UIImage(systemName: "questionmark.square.fill")?.withRenderingMode(.alwaysTemplate)
            }
        }
        
        static var searchIcon: UIImage? {
            UIImage(systemName: "magnifyingglass.circle.fill")?.withRenderingMode(.alwaysTemplate)
        }
        
        static var closeButtonIcon: UIImage? {
            UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
        }
        
        static var previewErrorImage: UIImage? {
            return UIImage(systemName: "xmark.circle")?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    public enum LocalizedStrings {
        public static let search = NSLocalizedString("Base.Search", value: "Search", comment: "The default title of the search button for the Base FleksyApps")
        
        // MARK: - Error messages
        
        public static let noConnectionError = NSLocalizedString("BaseApp.Error.NoConnection", value: "There is no internet connection.", comment: "The user-facing error message for the lack of internet connection.")
        
        public static let timeoutError = NSLocalizedString("BaseApp.Error.Timeout", value: "Request timed out.", comment: "The user-facing error message for a request that timed out.")
        
        public static let badURLError = NSLocalizedString("BaseApp.Error.BadURL", value: "Error: bad URL.", comment: "The user-facing error message for a bad URL error.")
        
        public static let badServerResponseError = NSLocalizedString("BaseApp.Error.BadServerResponse", value: "Received a bad response from the server.", comment: "The user-facing error message for a bad server response.")
        
        public static let requestCancelledError = NSLocalizedString("BaseApp.Error.RequestCancelled", value: "The request was cancelled", comment: "The user-facing error message for a cancelled request.")
        
        public static func invalidHTTPStatusCodeError(_ statusCode: Int) -> String {
            String(format: NSLocalizedString("BaseApp.Error.InvalidHTTPStatusCodeFormat", value: "Error: invalid status code %d.", comment: "A user-facing error message for an invalid HTTP status code. The parameter is the HTTP status code of the request that failed."), statusCode)
        }
    
        public static let otherError = NSLocalizedString("BaseApp.Error.Other", value: "An unknown error occurred.", comment: "The user-facing error message for a generic error")
    }
}
