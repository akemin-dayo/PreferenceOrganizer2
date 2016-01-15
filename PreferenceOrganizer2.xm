#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.10
#endif

#define DPKG_PATH "/var/lib/dpkg/info/net.angelxwind.preferenceorganizer2.list"

#import "PreferenceOrganizer2.h"
#import "PO2Common.h"
#import "KarenLocalize/KarenLocalize.mm"

@interface PrefsListController : PSListController
@end

@interface PSUIPrefsListController : PSListController
@end

// Static specifier-overriding arrays (used when populating PSListController/etc)
static NSMutableArray *AppleAppSpecifiers, *SocialAppSpecifiers, *TweakSpecifiers, *AppStoreAppSpecifiers;

// Sneaky implementations of vanilla PSListControllers with the proper hidden specifiers
@implementation AppleAppSpecifiersController
-(NSArray *) specifiers {
	if (!_specifiers) {
		self.specifiers = AppleAppSpecifiers;
	}
	return _specifiers;
}
@end
@implementation SocialAppSpecifiersController
-(NSArray *) specifiers {
	if (!_specifiers) {
		self.specifiers = SocialAppSpecifiers; 
	}
	return _specifiers;
}
@end
@implementation TweakSpecifiersController
-(NSArray *) specifiers {
	if (!_specifiers) {
		self.specifiers = TweakSpecifiers;
	}
	return _specifiers;
}
@end
@implementation AppStoreAppSpecifiersController
-(NSArray *) specifiers {
	if (!_specifiers) {
		self.specifiers = AppStoreAppSpecifiers;
	}
	return _specifiers;
}
@end

static BOOL shouldShowAppleApps;
static BOOL shouldShowTweaks;
static BOOL shouldShowAppStoreApps;
static BOOL shouldShowSocialApps;
static BOOL shouldSyslogSpam;
static BOOL prefloaderDialogShown;
static NSString *appleAppsLabel;
static NSString *socialAppsLabel;
static NSString *tweaksLabel;
static NSString *appStoreAppsLabel;

static void PO2InitPrefs() {
	PO2SyncPrefs();
	PO2BoolPref(shouldSyslogSpam, syslogSpam, 0);
	PO2BoolPref(shouldShowAppleApps, ShowAppleApps, 1);
	PO2BoolPref(shouldShowTweaks, ShowTweaks, 1);
	PO2BoolPref(shouldShowAppStoreApps, ShowAppStoreApps, 1);
	PO2BoolPref(shouldShowSocialApps, ShowSocialApps, 1);
	initKarenLocalize(@"PreferenceOrganizer2");
	PO2StringPref(appleAppsLabel, AppleAppsName, karenLocalizedString(@"APPLE_APPS"));
	PO2StringPref(socialAppsLabel, SocialAppsName, karenLocalizedString(@"SOCIAL_APPS"));
	PO2StringPref(tweaksLabel, TweaksName, karenLocalizedString(@"TWEAKS"));
	PO2StringPref(appStoreAppsLabel, AppStoreAppsName, karenLocalizedString(@"APP_STORE_APPS"));
}

%hook PrefsListController
-(NSMutableArray *) specifiers {
	initKarenLocalize(@"PreferenceOrganizer2");
	// TODO: Find some way to determine if /Developer is a mountpoint or not programmatically
	// ...and find a way to programmatically determine preferenceloader version
	// (because system() feels so wrong)
	if (system("/sbin/mount | grep Developer") == 0 && (system("/usr/bin/dpkg-query -s preferenceloader | grep 2.2.3") || system("/usr/bin/dpkg-query -s preferenceloader | grep 2.2.4~alpha1") == 0)) {
		// need this conditional here because this method is called multiple times
		if (!prefloaderDialogShown) {
			UIAlertView *prefloaderAlert = [[UIAlertView alloc] initWithTitle:karenLocalizedString(@"PL223_TITLE")
				message:karenLocalizedString(@"PL223_CONTENT")
				delegate:self
				cancelButtonTitle:karenLocalizedString(@"OK_SAD")
				otherButtonTitles:nil];
			[prefloaderAlert show];
		}
		prefloaderDialogShown = 1;
	}

	NSMutableArray *specifiers = %orig();

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// Do a check for net.angelxwind.preferenceorganizer2
		if (access(DPKG_PATH, F_OK) == -1) {
			UIAlertView *aptAlert = [[UIAlertView alloc] initWithTitle:karenLocalizedString(@"WARNING")
				message:[NSString stringWithFormat:@"%@ %@ %@", karenLocalizedString(@"APT_DETAIL_1"), karenLocalizedString(@"APT_DETAIL_2"),karenLocalizedString(@"APT_DETAIL_3")]
				delegate:self
				cancelButtonTitle:karenLocalizedString(@"OK")
				otherButtonTitles:nil];
			[aptAlert show];
			NSLog(@"%@", karenLocalizedString(@"APT_DETAIL_1"));
			NSLog(@"%@", karenLocalizedString(@"APT_DETAIL_2"));
			NSLog(@"%@", karenLocalizedString(@"APT_DETAIL_3"));
		}

		// Okay, let's start pushing paper.
		int groupID = 0;
		NSMutableDictionary *organizableSpecifiers = [[NSMutableDictionary alloc] init];
		NSString *currentOrganizableGroup = nil;

		// Loop that runs through all specifiers in the main Settings area. Once it cycles
		// through all the specifiers for the pre-"Apple Apps" groups, starts filling the
		// organizableSpecifiers array. This currently compares identifiers to prevent issues
		// with extra groups (such as the single "Developer" group).
		// CASTLE -> STORE -> ... -> DEVELOPER_SETTINGS -> ...
		for (int i = 0; i < specifiers.count; i++) { // We can't fast enumerate when order matters
			PSSpecifier *s = (PSSpecifier *) specifiers[i];
			NSString *identifier = s.identifier ?: @"";

			// If we're not a group cell...
			if (s->cellType != 0) {

				// If we're hitting the Developer settings area, regardless of position, we need to steal 
				// its group specifier from the previous group and leave it out of everything.
				if ([identifier isEqualToString:@"DEVELOPER_SETTINGS"]) {
					NSMutableArray *lastSavedGroup = organizableSpecifiers[currentOrganizableGroup];
					[lastSavedGroup removeObjectAtIndex:lastSavedGroup.count-1];
				}

				// If we're in the first item of the iCloud/Mail/Notes... group, setup the key string, 
				// grab the group from the previously enumerated specifier, and get ready to shift things into it. 
				else if ([identifier isEqualToString:@"CASTLE"] ) {
					currentOrganizableGroup = identifier;
					
					NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
					[newSavedGroup addObject:specifiers[i-1]];
					[newSavedGroup addObject:s];

					[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
				}

				// If we're in the first item of the iTunes/Music/Videos... group, setup the key string, 
				// steal the group from the previously organized specifier, and get ready to shift things into it. 
				else if ([identifier isEqualToString:@"STORE"]) {
					currentOrganizableGroup = identifier;
					
					NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
					[newSavedGroup addObject:specifiers[i-1]];
					[newSavedGroup addObject:s];

					[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
				}

				else if (currentOrganizableGroup) {
					[organizableSpecifiers[currentOrganizableGroup] addObject:s];
				}

				// else: We're above all that organizational confusion, and should stay out of it.
			}

			// If we're in the group specifier for the social accounts area, just pop that specifier into a new
			// mutable array and get ready to shift things into it.
			else if ([identifier isEqualToString:@"SOCIAL_ACCOUNTS"]) {
				currentOrganizableGroup = identifier;

				NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
				[newSavedGroup addObject:s];

				[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
			}

			// If we've already encountered groups before, but THIS specifier is a group specifier, then it COULDN'T
			// have been any previously encountered group, but is still important to PreferenceOrganizer's organization.
			// So, it must either be the Tweaks or Apps section.
			else if (currentOrganizableGroup) {
				if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
					if (groupID < 2) {
						groupID++;
						currentOrganizableGroup = @"STORE";
					} else if (groupID == 2) {
						groupID++;
						currentOrganizableGroup = @"TWEAKS";
					} else {
						groupID++;
						currentOrganizableGroup = @"APPS";
					}
				} else {
					NSMutableArray *tweaksGroup = organizableSpecifiers[@"TWEAKS"];
					if (tweaksGroup && tweaksGroup.count > 1) { // Because of some unholy lingering group specifiers
						currentOrganizableGroup = @"APPS";
					} else {
						currentOrganizableGroup = @"TWEAKS";
					}
				}

				NSMutableArray *newSavedGroup = organizableSpecifiers[currentOrganizableGroup];
				if (!newSavedGroup) {
					newSavedGroup = [[NSMutableArray alloc] init];
				}

				[newSavedGroup addObject:s];
				[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
			}
			if (i == specifiers.count - 1 && groupID != 4) {
				groupID++;
				currentOrganizableGroup = @"APPS";
				NSMutableArray *newSavedGroup = organizableSpecifiers[currentOrganizableGroup];
				if (!newSavedGroup) {
					newSavedGroup = [[NSMutableArray alloc] init];
				}
				[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
			}
		}

		// Since no one can figure out why the iCloud preference pane crashes when organised... let's just exclude it. ┐(￣ー￣)┌

		for (PSSpecifier* specifier in organizableSpecifiers[@"STORE"]) {
			if ([specifier.identifier isEqualToString:@"CASTLE"]) {
				[(NSMutableArray *)organizableSpecifiers[@"STORE"] removeObject:specifier];
				break;
			}
		}

		for (PSSpecifier* specifier in organizableSpecifiers[@"CASTLE"]) {
			if ([specifier.identifier isEqualToString:@"CASTLE"]) {
				[(NSMutableArray *)organizableSpecifiers[@"CASTLE"] removeObject:specifier];
				break;
			}
		}

		AppleAppSpecifiers = [organizableSpecifiers[@"CASTLE"] retain];
		[AppleAppSpecifiers addObjectsFromArray:organizableSpecifiers[@"STORE"]];

		SocialAppSpecifiers = [organizableSpecifiers[@"SOCIAL_ACCOUNTS"] retain];

		NSMutableArray *tweaksGroup = organizableSpecifiers[@"TWEAKS"];
		if ([tweaksGroup count] != 0 && ((PSSpecifier *)tweaksGroup[0])->cellType == 0 && ((PSSpecifier *)tweaksGroup[1])->cellType == 0) {
			[tweaksGroup removeObjectAtIndex:0];
		}
		TweakSpecifiers = [tweaksGroup retain];

		AppStoreAppSpecifiers = [organizableSpecifiers[@"APPS"] retain];

		// Shuffling START!!
		// Make a group section for our special organized groups
		[specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
		
		if (shouldShowAppleApps && AppleAppSpecifiers) {
			[specifiers removeObjectsInArray:AppleAppSpecifiers];
			
			PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
			[appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
			[specifiers addObject:appleSpecifier];
		}

		if (shouldShowSocialApps && SocialAppSpecifiers) {
			[specifiers removeObjectsInArray:SocialAppSpecifiers];
			
			PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:socialAppsLabel target:self set:NULL get:NULL  detail:[SocialAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
			NSString *imagePath = @"/Applications/Preferences.app/FacebookSettings.png";
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
				imagePath = @"/System/Library/PrivateFrameworks/Preferences.framework/FacebookSettings.png";
			}
			[socialSpecifier setProperty:[UIImage imageWithContentsOfFile:imagePath] forKey:@"iconImage"];
			[specifiers addObject:socialSpecifier];
		}

		if (shouldShowTweaks && TweakSpecifiers) {
			[specifiers removeObjectsInArray:TweakSpecifiers];
			  
			PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:tweaksLabel target:self set:NULL get:NULL detail:[TweakSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
			[cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/POPreferences.bundle/Tweaks.png"] forKey:@"iconImage"];
			[specifiers addObject:cydiaSpecifier];
		}

		if (shouldShowAppStoreApps && AppStoreAppSpecifiers) {
			[specifiers removeObjectsInArray:AppStoreAppSpecifiers];

			PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:appStoreAppsLabel target:self set:NULL get:NULL detail:[AppStoreAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
			[appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
			[specifiers addObject:appstoreSpecifier];
		}
	});

	return specifiers;
}

-(void) _reallyLoadThirdPartySpecifiersForProxies:(id)arg1 withCompletion:(id)arg2 {
	%orig(arg1, arg2);
	if (shouldShowAppStoreApps) {
		int thirdPartyID = 0;
		NSMutableArray* specifiers = [[NSMutableArray alloc] initWithArray:((PSListController *)self).specifiers];
		for (int i = 0; i < [specifiers count]; i++) {
			PSSpecifier* item = [specifiers objectAtIndex:i];
			if ([item.identifier isEqualToString:@"THIRD_PARTY_GROUP"]) {
				thirdPartyID = i;
				break;
			}
		}
		for (int i = thirdPartyID + 1; i < [specifiers count]; i++) {
			[AppStoreAppSpecifiers addObject:specifiers[i]];
		}

		while ([specifiers count] > thirdPartyID + 1) {
			[specifiers removeLastObject];
		}
		((PSListController *)self).specifiers = specifiers;
	}
}

-(void) refresh3rdPartyBundles {
	%orig();
	NSMutableArray *organizableSpecifiers = [[NSMutableArray alloc] init];
	NSArray *unorganizedSpecifiers = MSHookIvar<NSArray *>(self, "_specifiers"); // from PSListController
	
	// Loop through, starting at the bottom, every specifier in the FINAL Settings group
	// (the App Store apps), until we reach a group. Then we know we must be encountering
	// either the Developer or Tweak areas, so we should bust out right away.
	for (int i = unorganizedSpecifiers.count - 1; ((PSSpecifier *)unorganizedSpecifiers[i])->cellType != 0; i--) {
		[organizableSpecifiers addObject:unorganizedSpecifiers[i]];
	}

	// Remove all the refreshed app specifiers from the main list, then switch up the
	// specifiers found in the global PreferenceOrganizer variable that takes care of that.
	for (PSSpecifier *s in organizableSpecifiers) {
		[self removeSpecifier:s];
	}

	[AppStoreAppSpecifiers release];
	AppStoreAppSpecifiers = [organizableSpecifiers retain];
}

-(void) reloadSpecifiers {
	return; // Nah dawg you've come to the wrong part 'a town...
}
%end

%ctor {
	%init(PrefsListController = objc_getClass((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) ? "PSUIPrefsListController" : "PrefsListController"));
	PO2InitPrefs();
	PO2Observer(PO2InitPrefs, "net.angelxwind.preferenceorganizer2-PreferencesChanged");
}