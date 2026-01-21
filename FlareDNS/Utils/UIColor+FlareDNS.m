//
//  UIColor+FlareDNS.m
//  FlareDNS
//
//  Created by Vincent Yang on 1/21/26.
//

#import "UIColor+FlareDNS.h"

@implementation UIColor (FlareDNS)

+ (UIColor *)cf_primaryBackgroundColor {
    // iOS 16+ supports dynamic colors via trait collections.
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        }
        return [UIColor whiteColor];
    }];
}

+ (UIColor *)cf_secondaryBackgroundColor {
    // Secondary card-like surface (dynamic for Light/Dark).
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            // Slightly lighter for better contrast with dark background
            return [UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1.0];
        }
        // A subtle elevated surface in light mode
        return [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    }];
}

+ (UIColor *)cf_groupedBackgroundColor {
    // Background behind inset/grouped lists (dynamic for Light/Dark).
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        }
        return [UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:1.0];
    }];
}

+ (UIColor *)cf_primaryTextColor {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) ? [UIColor whiteColor] : [UIColor blackColor];
    }];
}

+ (UIColor *)cf_secondaryTextColor {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0];
        }
        return [UIColor colorWithRed:0.38 green:0.38 blue:0.40 alpha:1.0];
    }];
}

+ (UIColor *)cf_tertiaryTextColor {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.40 green:0.40 blue:0.42 alpha:1.0];
        }
        return [UIColor colorWithRed:0.55 green:0.55 blue:0.57 alpha:1.0];
    }];
}

+ (UIColor *)cf_accentColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
}

+ (UIColor *)cf_orangeColor {
    return [UIColor colorWithRed:0.96 green:0.65 blue:0.14 alpha:1.0];
}

+ (UIColor *)cf_greenColor {
    return [UIColor colorWithRed:0.2 green:0.78 blue:0.35 alpha:1.0];
}

+ (UIColor *)cf_redColor {
    return [UIColor colorWithRed:1.0 green:0.27 blue:0.23 alpha:1.0];
}

+ (UIColor *)cf_chartBlueColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
}

+ (UIColor *)cf_chartGradientStartColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.3];
}

+ (UIColor *)cf_chartGradientEndColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.0];
}

@end
