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
        NSMutableDictionary *organizableSpecifiers = [[NSMutableDictionary alloc] init];
        NSString *currentOrganizableGroup; BOOL mustBeTweaks, mustBeApps;

        // Loop that runs through all specifiers in the main Settings area. Once it cycles
        // through all the specifiers for the pre-"Apple Apps" groups, starts filling the
        // organizableSpecifiers array. This currently compares identifiers to prevent issues
        // with extra groups (such as the single "Developer" group).
        // CASTLE -> STORE -> ... -> DEVELOPER_SETTINGS -> ...
        for (int i = 0; i < specifiers.count; i++) { // We can't fast enumerate when order matters
            PSSpecifier *s = (PSSpecifier *) specifiers[i];

            // If we're not a group cell...
            if (s.cellType != 0) {

                // If we're hitting the Developer settings area, regardless of position, we need to steal 
                // its group specifier from the previous group and leave it out of everything.
                if ([s.identifier isEqualToString:@"DEVELOPER_SETTINGS"]) {
                    NSMutableArray *lastSavedGroup = organizableSpecifiers[currentOrganizableGroup];
                    [lastSavedGroup removeObjectAtIndex:lastSavedGroup.count-1];
                    continue;
                }

                // If we're in the first item of the iCloud/Mail/Notes... group, setup the key string, 
                // grab the group from the previously enumerated specifier, and get ready to shift things into it. 
                else if ([s.identifier isEqualToString:@"CASTLE"] ) {
                    currentOrganizableGroup = s.identifier;
                    
                    NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:specifiers[i-1]];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
                }

                // If we're in the first item of the iTunes/Music/Videos... group, setup the key string, 
                // steal the group from the previously organized specifier, and get ready to shift things into it. 
                else if ([s.identifier isEqualToString:@"STORE"]) {
                    currentOrganizableGroup = s.identifier;
                    
                    NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:specifiers[i-1]];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
                }
            }

            // If we're in the group specifier for the social accounts area, just pop that specifier into a new
            // mutable array and get ready to shift things into it.
            else if ([s.identifier isEqualToString:@"SOCIAL_ACCOUNTS"]) {
                currentOrganizableGroup = s.identifier;

                NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                [newSavedGroup addObject:s];

                [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
            }

            // If we've already encountered groups before, but THIS specifier is a group specifier, then it COULDN'T
            // have been any previously encountered group, but is still important to PrefernceOrganizer's organization.
            // So, it must either be the Tweaks or Apps section. We check if we've never had to make this decision before
            // (in which case both BOOLs would be false), and if so, it must be tweaks. But, if the first BOOL is true,
            // and we're still encountering this group specifier, then it must be apps. Then, preserve the group
            // specifier and start iterating as usual.
            else if (currentOrganizableGroup) {
                if (!mustBeTweaks && !mustBeApps) {
                    mustBeTweaks = YES;
                }

                else if (mustBeTweaks && !mustBeApps) {
                    mustBeApps = YES;
                }

                if (mustBeTweaks) {
                     NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:@"TWEAKS"];
                }

                else {
                     NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:@"APPS"];
                }
            }

            // If we're in a group that should be organized (so, we just iterated at least one
            // step after any of the above) branches, then organize that group! This is different from
            // the above branch because the above "else if" checked if NONE of the above conditions
            // were true, but currentOrganizableGroup was valid. This checks if currentOrganizableGroup
            // is valid after at least ONE of the above conditions was true (including that else if).
            if (currentOrganizableGroup) {
                [organizableSpecifiers[currentOrganizableGroup] addObject:s];
            }

            // else: We're above all that organizational confusion, and should stay out of it.
        }

        AppleAppSpecifiers = [organizableSpecifiers[@"CASTLE"] retain];
        [AppleAppSpecifiers addObjectsFromArray:organizableSpecifiers[@"STORE"]];

        SocialAppSpecifiers = [organizableSpecifiers[@"SOCIAL_ACCOUNTS"] retain];
        TweakSpecifiers = [organizableSpecifiers[@"TWEAKS"] retain];
        AppStoreAppSpecifiers = [organizableSpecifiers[@"APPS"] retain];
        
        // Time to being the shuffling!
        NSLog(@"-karen pops out from her hiding hole-");

        // Don't believe this is necessary, think there will already
        // be a group hanging around somewhere at this time. 
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
        
        if (showAppleApps && AppleAppSpecifiers) {
            [specifiers removeObjectsInArray:AppleAppSpecifiers];
            
            PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
            [specifiers addObject:appleSpecifier];
        }

        if (showSocialApps && SocialAppSpecifiers) {
            [specifiers removeObjectsInArray:SocialAppSpecifiers];
           
            PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:socialAppsLabel target:self set:NULL get:NULL  detail:[SocialAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [socialSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/FacebookSettings.png"] forKey:@"iconImage"];
            [specifiers addObject:socialSpecifier];
        }

        if (showTweaks && TweakSpecifiers) {
            [specifiers removeObjectsInArray:TweakSpecifiers];
              
            PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:tweaksLabel target:self set:NULL get:NULL detail:[TweakSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/POPreferences.bundle/Tweaks.png"] forKey:@"iconImage"];
            [specifiers addObject:cydiaSpecifier];
        }

        if (showAppStoreApps && AppStoreAppSpecifiers) {
            [specifiers removeObjectsInArray:AppStoreAppSpecifiers];
            
            PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:appStoreAppsLabel target:self set:NULL get:NULL detail:[AppStoreAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
            [specifiers addObject:appstoreSpecifier];
        }
    });

    return specifiers;
}

- (void)refresh3rdPartyBundles {
    %orig();

    NSMutableArray *organizableSpecifiers = [[NSMutableArray alloc] init];
    NSArray *unorganizedSpecifiers = MSHookIvar<NSArray *>(self, "_specifiers"); // from PSListController
    
    // Loop through, starting at the bottom, every specifier in the FINAL Settings group
    // (the App Store apps), until we reach a group. Then we know we must be encountering
    // either the Developer or Tweak areas, so we should bust out right away.
    for (int i = unorganizedSpecifiers.count - 1; ((PSSpecifier *)unorganizedSpecifiers[i]).cellType != 0; i--) {
        [organizableSpecifiers addObject:unorganizedSpecifiers[i]];
    }

    // Remove all the refreshed app specifiers from the main list, then switch up the
    // specifiers found in the global PreferenceOrganizer variable that takes care of that.
    for (PSSpecifier *s in organizableSpecifiers) {
        [self removeSpecifier:s];
    }

    [AppStoreAppSpecifiers release];
    AppStoreAppSpecifiers = [organizableSpecifiers retain];
}

- (void)reloadSpecifiers {
    return; // Nah dawg you've come to the wrong part 'a town...
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
