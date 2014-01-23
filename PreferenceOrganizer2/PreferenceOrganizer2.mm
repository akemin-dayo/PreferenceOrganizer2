//
//  PreferenceOrganizer2.mm
//  PreferenceOrganizer 2
//
//  Created by Qusic & iLendSoft on 4/19/13.
//  Modified by Eliz on 6/1/14
//  Modified by Karen on 2014/01/19
//  Copyright (c) 2014 Eliz/Karen. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import "CaptainHook/CaptainHook.h"

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

static NSMutableArray *CydiaSpecifiers;
static NSMutableArray *AppStoreSpecifiers;
static NSMutableArray *SocialSpecifiers;

@interface UIImage (Private)
+(UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface CydiaSpecifiersController : PSListController
@end
@implementation CydiaSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = CydiaSpecifiers; }
    return _specifiers;
}
@end

@interface AppStoreSpecifiersController : PSListController
@end
@implementation AppStoreSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = AppStoreSpecifiers; }
    return _specifiers;
}
@end

@interface SocialSpecifiersController : PSListController
@end
@implementation SocialSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { self.specifiers = SocialSpecifiers; }
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
        SocialSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:5]]retain];
        AppStoreSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]]retain];
        if ([[[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group-1]][1] identifier]isEqualToString:@"DEVELOPER_SETTINGS"]) {
            if (group-2 >= 6) {
                CydiaSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group-2]]retain];
            }
        } else {
            if (group-1 >= 6) {
                CydiaSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group-1]]retain];
            }
        }
        
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
        if (SocialSpecifiers.count > 0) {
            [specifiers removeObjectsInArray:SocialSpecifiers];
            [SocialSpecifiers removeObjectAtIndex:0];
            PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Social" target:self set:NULL get:NULL
                                                                          detail:[SocialSpecifiersController class]
                                                                            cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [socialSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/FacebookSettings.png"]
                                  forKey:@"iconImage"];
            [specifiers addObject:socialSpecifier];
        }
        if (CydiaSpecifiers.count > 0) {
            [specifiers removeObjectsInArray:CydiaSpecifiers];
            [CydiaSpecifiers removeObjectAtIndex:0];
            PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Cydia" target:self set:NULL get:NULL
                                                                         detail:[CydiaSpecifiersController class]
                                                                           cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [cydiaSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.saurik.Cydia"
                                                                                   format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
            [specifiers addObject:cydiaSpecifier];
        }
        if (AppStoreSpecifiers.count > 0) {
            [specifiers removeObjectsInArray:AppStoreSpecifiers];
            [AppStoreSpecifiers removeObjectAtIndex:0];
            PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"App Store" target:self set:NULL get:NULL
                                                                            detail:[AppStoreSpecifiersController class]
                                                                              cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore"
                                                                                      format:0 scale:[UIScreen mainScreen].scale]
                                    forKey:@"iconImage"];
            [specifiers addObject:appstoreSpecifier];
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
    [AppStoreSpecifiers release];
    AppStoreSpecifiers = [savedSpecifiers retain];
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
