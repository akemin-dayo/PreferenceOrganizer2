#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface PreferencesAppController
-(void) preferenceOrganizerOpenTweakPane:(NSString *)name;
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