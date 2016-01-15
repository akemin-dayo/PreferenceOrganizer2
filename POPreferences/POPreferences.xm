#import "../PO2Common.h"
#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>
#import "../KarenLocalize/KarenLocalize.mm"

#define paypalURL @"https://www.paypal.com/myaccount/transfer/send/external?recipient=rei@angelxwind.net&amount=&currencyCode=USD&payment_type=Gift"

static BOOL shouldSyslogSpam;

static void PO2InitPrefs() {
	PO2SyncPrefs();
	PO2BoolPref(shouldSyslogSpam, syslogSpam, 0);
}

%ctor {
	PO2Observer(PO2InitPrefs, "net.angelxwind.preferenceorganizer2-PreferencesChanged");
	PO2InitPrefs();
}

@interface POListController : PSListController
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@interface BlackTextActionButtonCell : PSTableCell
-(UILabel *) textLabel;
@end

@implementation BlackTextActionButtonCell
-(void) layoutSubviews {
    [super layoutSubviews];
    UILabel* textLabel = [self textLabel];
    textLabel.textColor = [UIColor blackColor];
}
@end
#pragma clang diagnostic pop

@implementation POListController
- (NSArray *)specifiers{
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PreferenceOrganizer2" target:self] retain];
	}

	return _specifiers;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *POSettings = [NSDictionary dictionaryWithContentsOfFile:PO2PreferencePath];
	if (!POSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return POSettings[specifier.properties[@"key"]];
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PO2PreferencePath]];
	PO2Log([NSString stringWithFormat:@"%@",specifier.properties], shouldSyslogSpam);
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:PO2PreferencePath atomically:YES];
	NSDictionary *POSettings = [NSDictionary dictionaryWithContentsOfFile:PO2PreferencePath];
	PO2Log([NSString stringWithFormat:@"POSettings %@",POSettings], shouldSyslogSpam);
	PO2Log([NSString stringWithFormat:@"posting CFNotification %@", specifier.properties[@"PostNotification"]], shouldSyslogSpam);
	CFStringRef mikotoPost = (CFStringRef)specifier.properties[@"PostNotification"];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), mikotoPost, NULL, NULL, YES);
}

-(void) resetSettings {
	initKarenLocalize(@"PreferenceOrganizer2");
	NSError *error;
	if ([[NSFileManager defaultManager] removeItemAtPath:PO2PreferencePath error:&error]) {
	    UIAlertView *ripInPieces = [[UIAlertView alloc] initWithTitle:karenLocalizedString(@"PREFS_RESET_SUCCESS")
													message:karenLocalizedString(@"PREFS_RESET_SUCCESS_DETAIL")
													delegate:nil
													cancelButtonTitle:karenLocalizedString(@"OK_WINK")
													otherButtonTitles: nil];
		[ripInPieces show];
		[ripInPieces release];
	} else {
		UIAlertView *ripInPieces = [[UIAlertView alloc] initWithTitle:karenLocalizedString(@"ERROR")
													message:[NSString stringWithFormat:@"%@ %@", karenLocalizedString(@"ERROR_DETAIL"), [error localizedDescription]]
													delegate:nil
													cancelButtonTitle:karenLocalizedString(@"OK_SAD")
													otherButtonTitles: nil];
		[ripInPieces show];
		[ripInPieces release];
	}
}

-(void) donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:paypalURL]];
}

-(void) killPreferences {
	initKarenLocalize(@"PreferenceOrganizer2");
	UIAlertView *suicidalPreferences = [[UIAlertView alloc] initWithTitle:karenLocalizedString(@"PREFS_IS_KILL")
		message:karenLocalizedString(@"PREFS_IS_KILL_DETAIL")
		delegate:self
		cancelButtonTitle:karenLocalizedString(@"OK")
		otherButtonTitles:nil];
	[suicidalPreferences show];
	[suicidalPreferences release];
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		system("/usr/bin/killall -9 Preferences");
	}
}
@end

@interface POEditTextCell : PSEditableTableCell
@end

@implementation POEditTextCell
-(BOOL) textFieldShouldReturn:(id)arg1 {
	return 1;
}
@end