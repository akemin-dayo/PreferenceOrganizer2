//
//  PreferenceOrganizer2.h
//  PreferenceOrganizer 2
//
//  Copyright (c) 2013-2014 Karen Tsai <angelXwind@angelxwind.net>, Eliz, Julian Weiss <insanjmail@gmail.com>, ilendemli. All rights reserved.
//  

// Theos / Logos by Dustin Howett
// see https://github.com/DHowett/theos

#import <Foundation/Foundation.h>
#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>
#import "substrate.h"

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