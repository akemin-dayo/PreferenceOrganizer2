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