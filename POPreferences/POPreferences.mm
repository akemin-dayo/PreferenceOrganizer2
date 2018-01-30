#import "../PO2Common.h"
#import <KarenLocalizer/KarenLocalizer.h>
#import <KarenPrefs/KarenPrefsListController.h>
#import <KarenPrefs/KarenPrefsAnimatedExitToSpringBoard.h>
#import <UIKit/UIKit.h>

NSString *paypalURL = @"https://paypal.me/angelXwind";

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
@end

__attribute__((constructor))
void karenLocalizer_init() {
	karenLocalizer = [[KarenLocalizer alloc] initWithKarenLocalizerBundle:@"PreferenceOrganizer2"];
}