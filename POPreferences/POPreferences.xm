#import "../PO2Common.h"
#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

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
	NSError *error;
	if ([[NSFileManager defaultManager] removeItemAtPath:PO2PreferencePath error:&error]) {
	    UIAlertView *ripInPieces = [[UIAlertView alloc] initWithTitle:@"PreferenceOrganizer 2 Preferences Reset Successfully"
													message:@"PreferenceOrganizer 2's preferences have been successfully reset to default values."
													delegate:nil
													cancelButtonTitle:@"OK (^_-)-☆"
													otherButtonTitles: nil];
		[ripInPieces show];
		[ripInPieces release];
	} else {
		UIAlertView *ripInPieces = [[UIAlertView alloc] initWithTitle:@"Error ━Σ(ﾟДﾟ|||)━"
													message:[NSString stringWithFormat:@"PreferenceOrganizer 2 was unable to reset settings! NSError info: %@", [error localizedDescription]]
													delegate:nil
													cancelButtonTitle:@"OK (・へ・)"
													otherButtonTitles: nil];
		[ripInPieces show];
		[ripInPieces release];
	}
}

-(void) killPreferences {
	UIAlertView *suicidalPreferences = [[UIAlertView alloc] initWithTitle:@"Note"
		message:@"The Preferences app will now kill itself to apply changes. This is not a crash."
		delegate:self
		cancelButtonTitle:@"OK"
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
- (BOOL)textFieldShouldReturn:(id)arg1 {
	return YES;
}
@end