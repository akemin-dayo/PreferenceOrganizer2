//
//  PreferenceOrganizer2.h
//  PreferenceOrganizer 2
//
//  Copyright (c) 2013-2014 Karen Tsai <angelXwind@angelxwind.net>, Eliz, ilendemli. All rights reserved.
//  Fork Copyright (c) 2014 Julian Weiss <insanjmail@gmail.com>
//  

// Theos / Logos by Dustin Howett
// see https://github.com/DHowett/theos

#import <Foundation/Foundation.h>
#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>
#import "substrate.h"

@interface PreferencesAppController (Private)
- (void)preferenceOrganizerOpenTweakPane:(NSString *)name;
@end

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface AppleAppSpecifiersController : PSListController
@end

@interface TweakSpecifiersController : PSListController
@end

@interface AppStoreAppSpecifiersController : PSListController
@end

@interface SocialAppSpecifiersController : PSListController
@end