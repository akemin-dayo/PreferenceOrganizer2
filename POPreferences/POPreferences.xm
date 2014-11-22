#import "../PreferenceOrganizer2.h"

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
	NSDictionary *POSettings = [NSDictionary dictionaryWithContentsOfFile:POPreferencePath];
	if (!POSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return POSettings[specifier.properties[@"key"]];
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:POPreferencePath]];
	NSLog(@"PreferenceOrganizer2: [DEBUG] %@",specifier.properties);
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:POPreferencePath atomically:YES];
	NSDictionary *POSettings = [NSDictionary dictionaryWithContentsOfFile:POPreferencePath];
	NSLog(@"PreferenceOrganizer2: [DEBUG] POSettings %@",POSettings);
	NSLog(@"PreferenceOrganizer2: [DEBUG] posting CFNotification %@", specifier.properties[@"PostNotification"]);
	CFStringRef mikotoPost = (CFStringRef)specifier.properties[@"PostNotification"];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), mikotoPost, NULL, NULL, YES);
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
		system("killall -9 Preferences");
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