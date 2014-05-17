//
//  PreferenceOrganizer2.xm
//  PreferenceOrganizer 2
//
//  Copyright (c) 2013-2014 Karen Tsai <angelXwind@angelxwind.net>, Eliz, ilendemli. All rights reserved.
//  Fork Copyright (c) 2014 Julian Weiss <insanjmail@gmail.com>
//  

// Theos / Logos by Dustin Howett
// see https://github.com/DHowett/theos

#import "PreferenceOrganizer2.h"

// Static specifier-overriding arrays (used when populating PSListController/etc)
static NSMutableArray *TweakSpecifiers, *AppStoreAppSpecifiers, *SocialAppSpecifiers, *AppleAppSpecifiers;

// Local preferences-specific variables, used when configuring at load
NSDictionary *settings;
BOOL showAppleApps, showTweaks, showAppStoreApps, showSocialApps; 
NSString *appleAppsLabel, *tweaksLabel, *appStoreAppsLabel, *socialAppsLabel;

@implementation AppleAppSpecifiersController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.specifiers = AppleAppSpecifiers;
    }

    return _specifiers;
}

@end

@implementation TweakSpecifiersController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.specifiers = TweakSpecifiers;
    }

    return _specifiers;
}

@end

@implementation AppStoreAppSpecifiersController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.specifiers = AppStoreAppSpecifiers;
    }

    return _specifiers;
}

@end

@implementation SocialAppSpecifiersController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.specifiers = SocialAppSpecifiers; 
    }

    return _specifiers;
}

@end

%hook PrefsListController

- (NSMutableArray *)specifiers {
    NSMutableArray *specifiers = %orig();

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *savedSpecifiers = [[NSMutableDictionary alloc] init];
        NSInteger group = -1;

        for (PSSpecifier *s in specifiers) {
            if (s.cellType == 0) {
                group++;

                if (group >= 3) {
                    [savedSpecifiers setObject:[[NSMutableArray alloc] init] forKey:@(group)];
                } 
            }

            else if (group >= 3) {
                [savedSpecifiers[@(group)] addObject:s];
            }
        }
        
        AppleAppSpecifiers = [savedSpecifiers[@(3)] retain];
        [AppleAppSpecifiers addObjectsFromArray:savedSpecifiers[@(4)]];

        SocialAppSpecifiers = [savedSpecifiers[@(5)] retain];
        AppStoreAppSpecifiers = [savedSpecifiers[@(group)] retain];
        
        if (group - 2 >= 6) {
            TweakSpecifiers = [savedSpecifiers[@(group - 2)] retain];
        }

        else if (group - 1 >= 6) {
            TweakSpecifiers = [savedSpecifiers[@(group - 1)] retain];
        }
        
        NSLog(@"-karen pops out from her hiding hole-");
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
        
        if (showAppleApps) {
            if (AppleAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:AppleAppSpecifiers];
                [AppleAppSpecifiers removeObjectAtIndex:0];
                
                PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL  detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
                [specifiers addObject:appleSpecifier];
            }
        }

        if (showSocialApps) {
            if (SocialAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:SocialAppSpecifiers];
                [SocialAppSpecifiers removeObjectAtIndex:0];
               
                PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:socialAppsLabel target:self set:NULL get:NULL  detail:[SocialAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [socialSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/FacebookSettings.png"] forKey:@"iconImage"];
                [specifiers addObject:socialSpecifier];
            }
        }

        if (showTweaks) {
            if (TweakSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:TweakSpecifiers];
                [TweakSpecifiers removeObjectAtIndex:0];
              
                PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:tweaksLabel target:self set:NULL get:NULL detail:[TweakSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/POPreferences.bundle/Tweaks.png"] forKey:@"iconImage"];
                [specifiers addObject:cydiaSpecifier];
            }
        }

        if (showAppStoreApps) {
            if (AppStoreAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:AppStoreAppSpecifiers];
                [AppStoreAppSpecifiers removeObjectAtIndex:0];
                
                PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:appStoreAppsLabel target:self set:NULL get:NULL detail:[AppStoreAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
                [specifiers addObject:appstoreSpecifier];
            }
        }
    });

    return specifiers;
}

- (void)refresh3rdPartyBundles {
    %orig();

    NSMutableArray *savedSpecifiers = [[NSMutableArray alloc] init];
    BOOL go = NO; // really? :p
    
    for (PSSpecifier *s in MSHookIvar<NSArray *>(self, "_specifiers")) { // from PSListController
        if (!go && [s.identifier isEqualToString:@"App Store"]) {
            go = YES;
        }

        else if (go) {
            [savedSpecifiers addObject:s];
        }
    }

    for (PSSpecifier *s in savedSpecifiers) {
        [self removeSpecifier:s];
    }

    [savedSpecifiers removeObjectAtIndex:0];
    [AppStoreAppSpecifiers release];

    AppStoreAppSpecifiers = [savedSpecifiers retain];
}

- (void)reloadSpecifiers {
    return;
}

%end

%ctor {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/net.angelxwind.preferenceorganizer2.plist"];
    NSLog(@"-loaded settings at launch of prefs: %@-", settings);

    NSNumber *appleAppsValue = settings[@"ShowAppleApps"];
    showAppleApps = (appleAppsValue ? [appleAppsValue boolValue] : YES);

    NSNumber *tweaksValue = settings[@"ShowTweaks"];
    showTweaks = (tweaksValue ? [tweaksValue boolValue] : YES);

    NSNumber *appStoreAppsValue = settings[@"ShowAppStoreApps"];
    showAppStoreApps = (appStoreAppsValue ? [appStoreAppsValue boolValue] : YES);

    NSNumber *socialAppsValue = settings[@"ShowSocialApps"];
    showSocialApps = (socialAppsValue ? [socialAppsValue boolValue] : YES);

    NSString *appleAppsName = settings[@"AppleAppsName"];
    appleAppsLabel = (appleAppsName ?: @"Apple Apps");

    NSString *tweaksName = settings[@"TweaksName"];
    tweaksLabel = (tweaksName ?: @"Tweaks");

    NSString *appStoreAppsName = settings[@"AppStoreAppsName"];
    appStoreAppsLabel = (appStoreAppsName ?: @"App Store Apps");

    NSString *socialAppsName = settings[@"SocialAppsName"];
    socialAppsLabel = (socialAppsName ?: @"Social Apps");
}
