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

@end

@interface POEditTextCell : PSEditableTableCell
@end

@implementation POEditTextCell

- (BOOL)textFieldShouldReturn:(id)arg1 {
	return YES;
}

@end