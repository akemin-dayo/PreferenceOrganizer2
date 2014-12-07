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
#define POPreferencePath @"/User/Library/Preferences/net.angelxwind.preferenceorganizer2.plist"
#define STRINGIFY_(x) #x
#define STRINGIFY(x) STRINGIFY_(x)
#define POBoolLog(argBool) NSLog(@"PreferenceOrganizer2: [INFO] %s = %d", #argBool, argBool)
#define POPref(var, key, default) do { \
	NSNumber *key = POSettings[@STRINGIFY(key)]; \
	var = key ? [key boolValue] : default; \
	POBoolLog(var); \
} while (0)
#define POObserver(funcToCall, listener) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)funcToCall, CFSTR(listener), NULL, CFNotificationSuspensionBehaviorCoalesce);
#define POSyncPrefs() \
	NSLog(@"PreferenceOrganizer2: [INFO] PreferenceOrganizer 2 (C) 2013-2014 Karen Tsai (angelXwind), Eliz, Julian Weiss (insanj), ilendemli"); \
	NSLog(@"PreferenceOrganizer2: [INFO] loading net.angelxwind.preferenceorganizer2 prefs"); \
	NSDictionary *POSettings = [NSDictionary dictionaryWithContentsOfFile:POPreferencePath]; \
	NSLog(@"PreferenceOrganizer2: [INFO] PreferenceOrganizer2 prefs have been synced, awaiting initialisation from PreferenceOrganizer2 dylib...");

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