//  AppTheme+BestColor.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

extension AppTheme {
    
    /// This (computed) variable returns the best color to use in conjuction with the `foreground` color of the receiver.
    /// It takes into account the other colors in the `AppTheme` (i.e. `background` and `accent`).
    ///
    /// In certain situations we need to choose a color that contrasts enough with the `foreground` color (e.g. cases
    /// where the foreground color is used as a background, such as selected category).
    ///
    /// This assumes that the foreground color is opaque (alpha channel is 1).
    var bestContrastColorForForeground: UIColor {
        let betterColorForForeground = [background, accent].first {
            foreground.hasHighEnoughContrastWith(otherColor: $0)
        }
        
        // If neither the background or the accent work well, we return
        // the best option between white or black
        return betterColorForForeground ?? blackOrWhiteForForeground
    }
    
    /// Returns the color between black or white that has higher contrast with the receive's `foreground`.
    private var blackOrWhiteForForeground: UIColor {
        let betterColor = [UIColor.white, UIColor.black].max {
            foreground.backgroundContrastRatioFor(foregroundColor: $0) < foreground.backgroundContrastRatioFor(foregroundColor: $1)
        }
        return betterColor!
    }
}

fileprivate extension UIColor {
    /// Assumes the receiver will be used for background and has alpha = 1 (is opaque).
    func backgroundContrastRatioFor(foregroundColor: UIColor) -> CGFloat {
        
        // Get the RGB components of the colors (assyuming bgAlpha == 1)
        var bgRed: CGFloat = 0, bgGreen: CGFloat = 0, bgBlue: CGFloat = 0
        self.getRed(&bgRed, green: &bgGreen, blue: &bgBlue, alpha: nil)
        
        var fgRed: CGFloat = 0, fgGreen: CGFloat = 0, fgBlue: CGFloat = 0, fgAlpha: CGFloat = 0
        foregroundColor.getRed(&fgRed, green: &fgGreen, blue: &fgBlue, alpha: &fgAlpha)
        
        // Consider alpha in foreground
        fgRed = fgRed * fgAlpha + bgRed * (1 - fgAlpha)
        fgGreen = fgGreen * fgAlpha + bgGreen * (1 - fgAlpha)
        fgBlue = fgBlue * fgAlpha + bgBlue * (1 - fgAlpha)
        
        // Calculate the relative luminance of the background and foreground colors
        // (see https://www.w3.org/TR/WCAG20/#contrast-ratiodef)
        let bgLuminance = 0.2126 * inv_gam_sRGB(ic: bgRed) + 0.7152 * inv_gam_sRGB(ic: bgGreen) + 0.0722 * inv_gam_sRGB(ic: bgBlue)
        let fgLuminance = 0.2126 * inv_gam_sRGB(ic: fgRed) + 0.7152 * inv_gam_sRGB(ic: fgGreen) + 0.0722 * inv_gam_sRGB(ic: fgBlue)
        
        // Calculate the contrast ratio between the two colors (considering alpha)
        let contrastRatio = (max(bgLuminance, fgLuminance) + 0.05) / (min(bgLuminance, fgLuminance) + 0.05)
        
        return contrastRatio
    }
        
    func hasHighEnoughContrastWith(otherColor: UIColor) -> Bool {
        let minContrastRatio: CGFloat = 4.5 // Min contrast ratio for AA level of contrast
        return backgroundContrastRatioFor(foregroundColor: otherColor) >= minContrastRatio
    }
    
    private func inv_gam_sRGB(ic:CGFloat) -> CGFloat {
        if ic <= 0.03928 {
            return ic / 12.92
        } else {
            return pow((ic + 0.055) / (1.055), 2.4)
        }
    }
}
