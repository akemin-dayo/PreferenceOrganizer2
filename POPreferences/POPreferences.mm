#import "../PO2Common.h"
#import <KarenLocalizer/KarenLocalizer.h>
#import <KarenPrefs/KarenPrefsListController.h>
#import <KarenPrefs/KarenPrefsBannerCell.h>
#import <KarenPrefs/KarenPrefsCustomColorSwitchCell.h>
#import <KarenPrefs/KarenPrefsAnimatedExitToSpringBoard.h>
#import <KarenPrefs/KarenPrefsCustomTextColorButtonCell.h>
#import <UIKit/UIKit.h>

NSString *paypalURL = @"https://paypal.me/akemindayo";
UIColor *POColor = [UIColor colorWithRed:255.0f/255.0f green:168.0f/255.0f blue:0.0f/255.0f alpha:1.0];

KarenLocalizer *karenLocalizer;

@interface POListController : KarenPrefsListController
@end
@implementation POListController
-(NSString *) karenPrefsLoadFromPlist {
	return @"PreferenceOrganizer2";
}
-(void) resetSettings {
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:PO2PreferencePath error:&error];
	if (!error) {
	    UIAlertView *resetSettingsDiag = [[UIAlertView alloc] initWithTitle:[karenLocalizer karenLocalizeString:@"PREFS_RESET_SUCCESS"]
													message:[karenLocalizer karenLocalizeString:@"PREFS_RESET_SUCCESS_DETAIL"]
													delegate:nil
													cancelButtonTitle:[karenLocalizer karenLocalizeString:@"OK_WINK"]
													otherButtonTitles: nil];
		[resetSettingsDiag show];
	} else {
		UIAlertView *resetSettingsDiag = [[UIAlertView alloc] initWithTitle:[karenLocalizer karenLocalizeString:@"ERROR"]
													message:[NSString stringWithFormat:@"%@ %@", [karenLocalizer karenLocalizeString:@"ERROR_DETAIL"], [error localizedDescription]]
													delegate:nil
													cancelButtonTitle:[karenLocalizer karenLocalizeString:@"OK_SAD"]
													otherButtonTitles: nil];
		[resetSettingsDiag show];
	}
}
-(void) closeSettings {
	[[UIApplication sharedApplication] karenPrefsAnimatedExit];
}
-(NSString *) karenPrefsDonateURL {
	return paypalURL;
}
-(UIColor *) karenPrefsCustomTintColor {
	return POColor;
}
@end

@interface POSwitchCell : KarenPrefsCustomColorSwitchCell
@end
@implementation POSwitchCell
-(UIColor *) karenPrefsCustomSwitchColor {
	return POColor;
}
@end

@interface POBannerCell : KarenPrefsBannerCell
@end
@implementation POBannerCell
-(NSString *) karenPrefsBannerLoadFromImage {
	return @"PreferenceOrganizer2Banner";
}
@end

@interface POButtonCell : KarenPrefsCustomTextColorButtonCell
@end
@implementation POButtonCell
-(UIColor *) karenPrefsCustomTextColor {
	return (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) ? POColor : nil;
}
@end

__attribute__((constructor))
void karenLocalizer_init() {
	karenLocalizer = [[KarenLocalizer alloc] initWithKarenLocalizerBundle:@"PreferenceOrganizer2"];
}