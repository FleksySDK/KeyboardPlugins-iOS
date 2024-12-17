//  BaseConstants.swift
//  FleksyApps
// 
//  Copyright © 2023 Thingthing. All rights reserved.
//
    

import UIKit

/// Constants used on a base app.
public enum BaseConstants {
    enum Images {
        /// A question mark.
        ///
        /// The default app icon on the carousel if none is provided.
        static var defaultAppIcon: UIImage? {
            if #available(iOS 15, *) {
                return UIImage(systemName: "questionmark.app.fill")?.withRenderingMode(.alwaysTemplate)
            } else {
                return UIImage(systemName: "questionmark.square.fill")?.withRenderingMode(.alwaysTemplate)
            }
        }
        
        static var searchIcon: UIImage? {
            UIImage(systemName: "magnifyingglass")?.withRenderingMode(.alwaysTemplate)
        }
        
        static var backButtonIcon: UIImage? {
            UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate)
        }
        
        static var previewErrorImage: UIImage? {
            return UIImage(systemName: "xmark.circle")?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    /// A set of localized strings for the BaseApp.
    public enum LocalizedStrings {
        /// The default text for the search actions in the BaseApp.
        public static let search = NSLocalizedString("Base.Search", value: "Search", comment: "The default title of the search button for the Base FleksyApps")
        
        // MARK: - Error messages
        
        static let noConnectionError = NSLocalizedString("BaseApp.Error.NoConnection", value: "There is no internet connection.", comment: "The user-facing error message for the lack of internet connection")
        
        static let timeoutError = NSLocalizedString("BaseApp.Error.Timeout", value: "Request timed out.", comment: "The user-facing error message for a request that timed out")
        
        static let badURLError = NSLocalizedString("BaseApp.Error.BadURL", value: "Error: bad URL.", comment: "The user-facing error message for a bad URL error.")
        
        static let badServerResponseError = NSLocalizedString("BaseApp.Error.BadServerResponse", value: "Received a bad response from the server.", comment: "The user-facing error message for a bad server response.")
        
        static let requestCancelledError = NSLocalizedString("BaseApp.Error.RequestCancelled", value: "The request was cancelled", comment: "The user-facing error message for a cancelled request")
        
        static func invalidHTTPStatusCodeError(_ statusCode: Int) -> String {
            String(format: NSLocalizedString("BaseApp.Error.InvalidHTTPStatusCodeFormat", value: "Error: invalid status code %d.", comment: "A user-facing error message for an invalid HTTP status code. The parameter is the HTTP status code of the request that failed"), statusCode)
        }
    
        static let otherError = NSLocalizedString("BaseApp.Error.Other", value: "An unknown error occurred.", comment: "The user-facing error message for a generic error")
    }
}
