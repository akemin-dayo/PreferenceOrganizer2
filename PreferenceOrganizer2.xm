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
static NSMutableArray *AppleAppSpecifiers, *SocialAppSpecifiers, *TweakSpecifiers, *AppStoreAppSpecifiers;

// Sneaky implementations of vanilla PSListControllers with the proper hidden specifiers
@implementation AppleAppSpecifiersController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.specifiers = AppleAppSpecifiers;
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

// Static function that chooses the first parameter if it's a non-nil, non-empty string, the second otherwise
static NSString * poValidNameForDefault(NSString *name, NSString *def) {
    if (name && [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        return name;
    }

    else {
        return def;
    }
}

%hook PrefsListController

- (NSMutableArray *)specifiers {
    NSMutableArray *specifiers = %orig();

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Read preferences....
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/net.angelxwind.preferenceorganizer2.plist"];

        NSNumber *appleAppsValue = settings[@"ShowAppleApps"];
        BOOL showAppleApps = (appleAppsValue ? [appleAppsValue boolValue] : YES);

        NSNumber *tweaksValue = settings[@"ShowTweaks"];
        BOOL showTweaks = (tweaksValue ? [tweaksValue boolValue] : YES);

        NSNumber *appStoreAppsValue = settings[@"ShowAppStoreApps"];
        BOOL showAppStoreApps = (appStoreAppsValue ? [appStoreAppsValue boolValue] : YES);

        NSNumber *socialAppsValue = settings[@"ShowSocialApps"];
        BOOL showSocialApps = (socialAppsValue ? [socialAppsValue boolValue] : YES);

        NSString *appleAppsLabel = poValidNameForDefault(settings[@"AppleAppsName"], @"Apple");
        NSString *socialAppsLabel = poValidNameForDefault(settings[@"SocialAppsName"], @"Social");
        NSString *tweaksLabel = poValidNameForDefault(settings[@"TweaksName"], @"Tweaks");
        NSString *appStoreAppsLabel = poValidNameForDefault(settings[@"AppStoreAppsName"], @"App Store");

        // Okay, let's start pushing paper.
        NSMutableDictionary *organizableSpecifiers = [[NSMutableDictionary alloc] init];
        NSString *currentOrganizableGroup = nil;

        // Loop that runs through all specifiers in the main Settings area. Once it cycles
        // through all the specifiers for the pre-"Apple Apps" groups, starts filling the
        // organizableSpecifiers array. This currently compares identifiers to prevent issues
        // with extra groups (such as the single "Developer" group).
        // CASTLE -> STORE -> ... -> DEVELOPER_SETTINGS -> ...
        for (int i = 0; i < specifiers.count; i++) { // We can't fast enumerate when order matters
            PSSpecifier *s = (PSSpecifier *) specifiers[i];
            NSString *identifier = s.identifier ?: @"";

            // If we're not a group cell...
            if (s.cellType != 0) {

                // If we're hitting the Developer settings area, regardless of position, we need to steal 
                // its group specifier from the previous group and leave it out of everything.
                if ([identifier isEqualToString:@"DEVELOPER_SETTINGS"]) {
                    NSMutableArray *lastSavedGroup = organizableSpecifiers[currentOrganizableGroup];
                    [lastSavedGroup removeObjectAtIndex:lastSavedGroup.count-1];
                }

                // If we're in the first item of the iCloud/Mail/Notes... group, setup the key string, 
                // grab the group from the previously enumerated specifier, and get ready to shift things into it. 
                else if ([identifier isEqualToString:@"CASTLE"] ) {
                    currentOrganizableGroup = identifier;
                    
                    NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:specifiers[i-1]];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
                }

                // If we're in the first item of the iTunes/Music/Videos... group, setup the key string, 
                // steal the group from the previously organized specifier, and get ready to shift things into it. 
                else if ([identifier isEqualToString:@"STORE"]) {
                    currentOrganizableGroup = identifier;
                    
                    NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                    [newSavedGroup addObject:specifiers[i-1]];
                    [newSavedGroup addObject:s];

                    [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
                }

                else if (currentOrganizableGroup) {
                    [organizableSpecifiers[currentOrganizableGroup] addObject:s];
                }

                // else: We're above all that organizational confusion, and should stay out of it.
            }

            // If we're in the group specifier for the social accounts area, just pop that specifier into a new
            // mutable array and get ready to shift things into it.
            else if ([identifier isEqualToString:@"SOCIAL_ACCOUNTS"]) {
                currentOrganizableGroup = identifier;

                NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
                [newSavedGroup addObject:s];

                [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
            }

            // If we've already encountered groups before, but THIS specifier is a group specifier, then it COULDN'T
            // have been any previously encountered group, but is still important to PrefernceOrganizer's organization.
            // So, it must either be the Tweaks or Apps section.
            else if (currentOrganizableGroup) {
                NSMutableArray *tweaksGroup = organizableSpecifiers[@"TWEAKS"];
                if (tweaksGroup && tweaksGroup.count > 1) { // Because of some unholy lingering group specifiers
                    currentOrganizableGroup = @"APPS";
                }

                else {
                    currentOrganizableGroup = @"TWEAKS";
                }

                NSMutableArray *newSavedGroup = organizableSpecifiers[currentOrganizableGroup];
                if (!newSavedGroup) {
                    newSavedGroup = [[NSMutableArray alloc] init];
                }

                [newSavedGroup addObject:s];
                [organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
            }
        }

        AppleAppSpecifiers = [organizableSpecifiers[@"CASTLE"] retain];
        [AppleAppSpecifiers addObjectsFromArray:organizableSpecifiers[@"STORE"]];

        SocialAppSpecifiers = [organizableSpecifiers[@"SOCIAL_ACCOUNTS"] retain];

        NSMutableArray *tweaksGroup = organizableSpecifiers[@"TWEAKS"];
        if (((PSSpecifier *)tweaksGroup[0]).cellType == 0 && ((PSSpecifier *)tweaksGroup[1]).cellType == 0) {
            [tweaksGroup removeObjectAtIndex:0];
        }
        TweakSpecifiers = [tweaksGroup retain];

        AppStoreAppSpecifiers = [organizableSpecifiers[@"APPS"] retain];
        
        // Time to being the shuffling!
        NSLog(@"-karen pops out from her hiding hole-");

        // Make a group section for our special organized groups
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
