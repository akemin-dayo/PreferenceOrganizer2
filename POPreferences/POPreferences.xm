#import <Preferences/Preferences.h>

@interface POListController : PSListController
@end

@implementation POListController

- (NSArray *)specifiers{
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PreferenceOrganizer2" target:self] retain];
	}

	return _specifiers;
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