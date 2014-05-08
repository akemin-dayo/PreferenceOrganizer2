//
//  PreferenceOrganizer2.mm
//  PreferenceOrganizer 2
//
//  Copyright (c) 2013-2014 Karen Tsai <angelXwind@angelxwind.net>, Eliz, iLendSoft. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import "CaptainHook/CaptainHook.h"

static NSMutableArray *TweakSpecifiers;
static NSMutableArray *AppStoreAppSpecifiers;
static NSMutableArray *SocialAppSpecifiers;
static NSMutableArray *AppleAppSpecifiers;

NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/net.angelxwind.preferenceorganizer2.plist"];

id appleAppsValue = [settings objectForKey:@"ShowAppleApps"];
bool showAppleApps = (appleAppsValue ? [appleAppsValue boolValue] : YES);

id tweaksValue = [settings objectForKey:@"ShowTweaks"];
bool showTweaks = (tweaksValue ? [tweaksValue boolValue] : YES);

id appStoreAppsValue = [settings objectForKey:@"ShowAppStoreApps"];
bool showAppStoreApps = (appStoreAppsValue ? [appStoreAppsValue boolValue] : YES);

id socialAppsValue = [settings objectForKey:@"ShowSocialApps"];
bool showSocialApps = (socialAppsValue ? [socialAppsValue boolValue] : YES);

@interface UIImage (Private)
+(UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface AppleAppSpecifiersController : PSListController
@end
@implementation AppleAppSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = AppleAppSpecifiers; }
    return _specifiers;
}
@end

@interface TweakSpecifiersController : PSListController
@end
@implementation TweakSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = TweakSpecifiers; }
    return _specifiers;
}
@end

@interface AppStoreAppSpecifiersController : PSListController
@end
@implementation AppStoreAppSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = AppStoreAppSpecifiers; }
    return _specifiers;
}
@end

@interface SocialAppSpecifiersController : PSListController
@end
@implementation SocialAppSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = SocialAppSpecifiers; }
    return _specifiers;
}
@end

CHDeclareClass(PrefsListController)
CHOptimizedMethod(0, self, NSMutableArray *, PrefsListController, specifiers)
{
    NSMutableArray *specifiers = CHSuper(0, PrefsListController, specifiers);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *savedSpecifiers = [NSMutableDictionary dictionary];
        NSInteger group = -1;
        for (PSSpecifier *s in specifiers) {
            if (s->cellType == 0) {
                group++;
                if (group >= 3) {
                    [savedSpecifiers setObject:[NSMutableArray array]forKey:[NSNumber numberWithInteger:group]];
                } else {
                    continue;
                }
            }
            if (group >= 3) {
                [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]]addObject:s];
            }
        }
        
        AppleAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:3]]retain];
        [AppleAppSpecifiers addObjectsFromArray:[savedSpecifiers objectForKey:[NSNumber numberWithInteger:4]]];
        SocialAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:5]]retain];
        AppStoreAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]]retain];
        
        if (group-2 >= 6) {
            TweakSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group-2]]retain];
        } else if (group-1 >= 6) {
            TweakSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group-1]]retain];
        }
        
        NSLog(@"-karen pops out from her hiding hole-");
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
        if (showAppleApps == 1) {
            if (AppleAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:AppleAppSpecifiers];
                [AppleAppSpecifiers removeObjectAtIndex:0];
                PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Apple Apps" target:self set:NULL get:NULL
                                                                             detail:[AppleAppSpecifiersController class]
                                                                               cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari"
                                                                                       format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
                [specifiers addObject:appleSpecifier];
            }
        }
        if (showSocialApps == 1) {
            if (SocialAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:SocialAppSpecifiers];
                [SocialAppSpecifiers removeObjectAtIndex:0];
                PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Social Apps" target:self set:NULL get:NULL
                                                                              detail:[SocialAppSpecifiersController class]
                                                                                cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [socialSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/FacebookSettings.png"]
                                      forKey:@"iconImage"];
                [specifiers addObject:socialSpecifier];
            }
        }
        if (showTweaks == 1) {
            if (TweakSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:TweakSpecifiers];
                [TweakSpecifiers removeObjectAtIndex:0];
                PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Tweaks" target:self set:NULL get:NULL
                                                                             detail:[TweakSpecifiersController class]
                                                                               cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceOrganizer2/Tweaks.png"]
                                     forKey:@"iconImage"];
            [   specifiers addObject:cydiaSpecifier];
            }
        }
        if (showAppStoreApps == 1) {
            if (AppStoreAppSpecifiers.count > 0) {
                [specifiers removeObjectsInArray:AppStoreAppSpecifiers];
                [AppStoreAppSpecifiers removeObjectAtIndex:0];
                PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"App Store Apps" target:self set:NULL get:NULL
                                                                                detail:[AppStoreAppSpecifiersController class]
                                                                                  cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
                [appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore"
                                                                                          format:0 scale:[UIScreen mainScreen].scale]
                                        forKey:@"iconImage"];
                [specifiers addObject:appstoreSpecifier];
            }
        }
    });
    return specifiers;
}
CHOptimizedMethod(0, self, void, PrefsListController, refresh3rdPartyBundles)
{
    CHSuper(0, PrefsListController, refresh3rdPartyBundles);
    NSMutableArray *savedSpecifiers = [NSMutableArray array];
    BOOL go = NO;
    for (PSSpecifier *s in CHIvar(self, _specifiers, NSMutableArray *)) {
        if (!go && [s.identifier isEqualToString:@"App Store"]) {
            go = YES;
            continue;
        }
        if (go) {
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
CHOptimizedMethod(0, self, void, PrefsListController, reloadSpecifiers) {}

CHConstructor
{
	@autoreleasepool {
        CHLoadLateClass(PrefsListController);
        CHHook(0, PrefsListController, specifiers);
        CHHook(0, PrefsListController, refresh3rdPartyBundles);
        CHHook(0, PrefsListController, reloadSpecifiers);
    }
}
