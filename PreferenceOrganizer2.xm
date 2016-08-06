#import "PreferenceOrganizer2.h"
#import "PO2Common.h"
#import "PO2Log.h"
#import <KarenLocalizer/KarenLocalizer.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_2
#define kCFCoreFoundationVersionNumber_iOS_9_2 1242.13
#endif

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
static BOOL ddiIsMounted = 0;
static BOOL shouldShuffle = 1;
static NSString *appleAppsLabel;
static NSString *socialAppsLabel;
static NSString *tweaksLabel;
static NSString *appStoreAppsLabel;

KarenLocalizer *karenLocalizer;

static NSMutableArray *unorganisedSpecifiers = nil;

static void PO2InitPrefs() {
	PO2SyncPrefs();
	PO2BoolPref(shouldSyslogSpam, syslogSpam, 0);
	PO2BoolPref(shouldShowAppleApps, ShowAppleApps, 1);
	PO2BoolPref(shouldShowTweaks, ShowTweaks, 1);
	PO2BoolPref(shouldShowAppStoreApps, ShowAppStoreApps, 1);
	PO2BoolPref(shouldShowSocialApps, ShowSocialApps, 1);
	karenLocalizer = [[KarenLocalizer alloc] initWithKarenLocalizerBundle:@"PreferenceOrganizer2"];
	PO2StringPref(appleAppsLabel, AppleAppsName, [karenLocalizer karenLocalizeString:@"APPLE_APPS"]);
	PO2StringPref(socialAppsLabel, SocialAppsName, [karenLocalizer karenLocalizeString:@"SOCIAL_APPS"]);
	PO2StringPref(tweaksLabel, TweaksName, [karenLocalizer karenLocalizeString:@"TWEAKS"]);
	PO2StringPref(appStoreAppsLabel, AppStoreAppsName, [karenLocalizer karenLocalizeString:@"APP_STORE_APPS"]);
}

/*
	##  #######   ######    ########    ##   
	   ##     ## ##    ##        ##     ##   
	## ##     ## ##             ##      ##   
	## ##     ##  ######       ##    ########
	## ##     ##       ##     ##        ##   
	## ##     ## ##    ##    ##         ##   
	##  #######   ######    ##          ##   
*/

%group iOS7Up
%hook PrefsListController
// The ages-old iCloud prefpane crashing bug is caused by the fact that the following method sometimes may be invoked by -[(PSUI)PrefsListController appleAccountsDidChange] which calls for [self specifierForID:@"CASTLE"]... but it won't exist when PO2 "organises" it.
// So, we implement our own method that just does nothing if the iCloud specifier is nil
-(void) _setupiCloudSpecifier:(PSSpecifier *)specifier {
	if (specifier == nil) {
		return;
	}
	%orig(specifier);
}
-(void) _setupiCloudSpecifierAsync:(PSSpecifier *)specifier {
	if (specifier == nil) {
		return;
	}
	%orig(specifier);
}
-(void) _setupiCloudSpecifier:(PSSpecifier *)specifier withPrimaryAccount:(id)arg {
	if (specifier == nil) {
		return;
	}
	%orig(specifier, arg);
}

-(NSMutableArray *) specifiers {
	NSMutableArray *specifiers = %orig();
	PO2Log([NSString stringWithFormat:@"originalSpecifiers = %@", specifiers], shouldSyslogSpam);

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// Save the original, unorganised specifiers
		if (unorganisedSpecifiers == nil) {
			unorganisedSpecifiers = [specifiers.copy retain];
		}
		// Do a check for net.angelxwind.preferenceorganizer2
		if (access(DPKG_PATH, F_OK) == -1) {
			UIAlertView *aptAlert = [[UIAlertView alloc] initWithTitle:[karenLocalizer karenLocalizeString:@"WARNING"]
				message:[NSString stringWithFormat:@"%@ %@ %@", [karenLocalizer karenLocalizeString:@"APT_DETAIL_1"], [karenLocalizer karenLocalizeString:@"APT_DETAIL_2"],[karenLocalizer karenLocalizeString:@"APT_DETAIL_3"]]
				delegate:self
				cancelButtonTitle:[karenLocalizer karenLocalizeString:@"OK"]
				otherButtonTitles:nil];
			[aptAlert show];
			PO2Log([NSString stringWithFormat:@"%@", [karenLocalizer karenLocalizeString:@"APT_DETAIL_1"]], 1);
			PO2Log([NSString stringWithFormat:@"%@", [karenLocalizer karenLocalizeString:@"APT_DETAIL_2"]], 1);
			PO2Log([NSString stringWithFormat:@"%@", [karenLocalizer karenLocalizeString:@"APT_DETAIL_3"]], 1);
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
					[lastSavedGroup removeObjectAtIndex:lastSavedGroup.count - 1];
					// If DEVELOPER_SETTINGS is present, then that means the DDI must have been mounted.
					ddiIsMounted = 1;
				}

				// If we're in the first item of the iCloud/Mail/Notes... group, setup the key string, 
				// grab the group from the previously enumerated specifier, and get ready to shift things into it. 
				else if ([identifier isEqualToString:@"CASTLE"] ) {
					currentOrganizableGroup = identifier;
					
					NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
					[newSavedGroup addObject:specifiers[i - 1]];
					[newSavedGroup addObject:s];

					[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
				}

				// If we're in the first item of the iTunes/Music/Videos... group, setup the key string, 
				// steal the group from the previously organized specifier, and get ready to shift things into it. 
				else if ([identifier isEqualToString:@"STORE"]) {
					currentOrganizableGroup = identifier;
					
					NSMutableArray *newSavedGroup = [[NSMutableArray alloc] init];
					// we don't need this, so that CASTLE and STORE can be in the same group
					//[newSavedGroup addObject:specifiers[i - 1]];
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
					// If the DDI is mounted, groupIDs will all shift down by 1, causing the categories to be sorted incorrectly.
					if (groupID < 2 + ddiIsMounted) {
						groupID++;
						currentOrganizableGroup = @"STORE";
					} else if (groupID == 2 + ddiIsMounted) {
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
			if (i == specifiers.count - 1 && groupID != 4 + ddiIsMounted) {
				groupID++;
				currentOrganizableGroup = @"APPS";
				NSMutableArray *newSavedGroup = organizableSpecifiers[currentOrganizableGroup];
				if (!newSavedGroup) {
					newSavedGroup = [[NSMutableArray alloc] init];
				}
				[organizableSpecifiers setObject:newSavedGroup forKey:currentOrganizableGroup];
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
			PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
			[appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
			// Setting this identifier for later use...
			[appleSpecifier setIdentifier:@"APPLE_APPS"];
			[specifiers addObject:appleSpecifier];
		}

		if (shouldShowSocialApps && SocialAppSpecifiers) {
			[specifiers removeObjectsInArray:SocialAppSpecifiers];
			PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:socialAppsLabel target:self set:NULL get:NULL  detail:[SocialAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
			[socialSpecifier setProperty:[UIImage imageWithContentsOfFile:(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) ? @"/System/Library/PrivateFrameworks/Preferences.framework/FacebookSettings.png" : @"/Applications/Preferences.app/FacebookSettings.png"] forKey:@"iconImage"];
			[specifiers addObject:socialSpecifier];
		}

		if (shouldShowTweaks && TweakSpecifiers) {
			[specifiers removeObjectsInArray:TweakSpecifiers];
			PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:tweaksLabel target:self set:NULL get:NULL detail:[TweakSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
			[cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/POPreferences.bundle/Tweaks.png"] forKey:@"iconImage"];
			[specifiers addObject:cydiaSpecifier];
		}

		if (shouldShowAppStoreApps && AppStoreAppSpecifiers) {
			[specifiers removeObjectsInArray:AppStoreAppSpecifiers];
			PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:appStoreAppsLabel target:self set:NULL get:NULL detail:[AppStoreAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
			[appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
			[specifiers addObject:appstoreSpecifier];
		}

		PO2Log([NSString stringWithFormat:@"organizableSpecifiers = %@", organizableSpecifiers], shouldSyslogSpam);
	});

	PO2Log([NSString stringWithFormat:@"shuffledSpecifiers = %@", specifiers], shouldSyslogSpam);
	return specifiers;
}

// Write custom -loadView method implementation that works with unorganised specifiers... which somehow fixes the infamous iOS 9.x iPad crash bug
// However, PreferenceLoader ultimately should be updated in order to fix the insertion bug present on iOS 9.x iPads, as stated by vit9696 (#9)
-(void) loadView {
	NSMutableArray *originalSpecifiers = MSHookIvar<NSMutableArray *>(self, "_specifiers");
	MSHookIvar<NSMutableArray *>(self, "_specifiers") = unorganisedSpecifiers;
	%orig();
	MSHookIvar<NSMutableArray *>(self, "_specifiers") = originalSpecifiers;
}

-(void) _reallyLoadThirdPartySpecifiersForProxies:(id)arg1 withCompletion:(id)arg2 {
	%orig(arg1, arg2);

	NSMutableArray* specifiers = [[NSMutableArray alloc] initWithArray:((PSListController *)self).specifiers];
	
	// Now begin organising specifiers that appear with this method...
	if (shouldShowAppleApps) {
		NSMutableArray *itemsToReallyAdd = [[NSMutableArray alloc] init];
		for (PSSpecifier *item in specifiers) {
			if ([item.identifier isEqualToString:@"com.apple.iBooks"]) {
				[itemsToReallyAdd addObject:item];
			} else if ([item.identifier isEqualToString:@"com.apple.podcasts"]) {
				[itemsToReallyAdd addObject:item];
			} else if ([item.identifier isEqualToString:@"com.apple.PassbookSettings"]) {
				[itemsToReallyAdd addObject:item];
			} else if ([item.identifier isEqualToString:@"com.apple.Passbook"]) {
				[itemsToReallyAdd addObject:item];
			} else if ([item.identifier isEqualToString:@"com.apple.news"]) {
				[itemsToReallyAdd addObject:item];
			}
		}
		[specifiers removeObjectsInArray:itemsToReallyAdd];
		if (shouldShuffle) {
			for (int i = 0; i < [specifiers count]; i++) {
				PSSpecifier *item = [specifiers objectAtIndex:i];
				if ([item.identifier isEqualToString:@"APPLE_APPS"]) {
					[AppleAppSpecifiers removeObjectsInArray:itemsToReallyAdd];
					[AppleAppSpecifiers addObjectsFromArray:itemsToReallyAdd];
					PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
					[appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
					[((PSListController *)self).specifiers replaceObjectAtIndex:i withObject:appleSpecifier];
				}
			}
			// don't run this part of the code again to prevent duplicates
			shouldShuffle = 0;
		}
	}

	if (shouldShowAppStoreApps) {
		int thirdPartyID = 0;
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
%end
%end

/*
	##  #######   ######     #######
	   ##     ## ##    ##   ##      
	## ##     ## ##         ##      
	## ##     ##  ######    ####### 
	## ##     ##       ##   ##    ##
	## ##     ## ##    ##   ##    ##
	##  #######   ######     ###### 
*/
%group iOS6
%hook PrefsListController
-(void) _setupiCloudSpecifier:(PSSpecifier *)specifier {
	if (specifier == nil) {
		return;
	}
	%orig();
}
-(NSMutableArray *) specifiers {
	NSMutableArray *specifiers = %orig();
	PO2Log([NSString stringWithFormat:@"originalSpecifiers = %@", specifiers], shouldSyslogSpam);
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableDictionary *savedSpecifiers = [NSMutableDictionary dictionary];
		NSInteger group = -1;
		for (PSSpecifier *s in specifiers) {
			if (s->cellType == 0) {
				group++;
				if (group >= 3) {
					[savedSpecifiers setObject:[NSMutableArray array] forKey:[NSNumber numberWithInteger:group]];
				} else {
					continue;
				}
			}
			if (group >= 3) {
				[[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]] addObject:s];
			}
		}
		
		AppleAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:3]] retain];
		[AppleAppSpecifiers addObjectsFromArray:[savedSpecifiers objectForKey:[NSNumber numberWithInteger:4]]];
		SocialAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:5]] retain];
		AppStoreAppSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]] retain];
		
		if (group - 2 >= 6) {
			TweakSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group - 2]] retain];
		} else if (group - 1 >= 6) {
			TweakSpecifiers = [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group - 1]] retain];
		}
		
		[specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
		if (shouldShowAppleApps) {
			if (AppleAppSpecifiers.count > 0) {
				[specifiers removeObjectsInArray:AppleAppSpecifiers];
				[AppleAppSpecifiers removeObjectAtIndex:0];
				PSSpecifier *appleSpecifier = [PSSpecifier preferenceSpecifierNamed:appleAppsLabel target:self set:NULL get:NULL detail:[AppleAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
				[appleSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.mobilesafari" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
				[specifiers addObject:appleSpecifier];
			}
		}
		if (shouldShowSocialApps) {
			if (SocialAppSpecifiers.count > 0) {
				[specifiers removeObjectsInArray:SocialAppSpecifiers];
				[SocialAppSpecifiers removeObjectAtIndex:0];
				PSSpecifier *socialSpecifier = [PSSpecifier preferenceSpecifierNamed:socialAppsLabel target:self set:NULL get:NULL detail:[SocialAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
				[socialSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Applications/Preferences.app/FacebookSettings.png"] forKey:@"iconImage"];
				[specifiers addObject:socialSpecifier];
			}
		}
		if (shouldShowTweaks) {
			if (TweakSpecifiers.count > 0) {
				[specifiers removeObjectsInArray:TweakSpecifiers];
				[TweakSpecifiers removeObjectAtIndex:0];
				PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:tweaksLabel target:self set:NULL get:NULL detail:[TweakSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
				[cydiaSpecifier setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/POPreferences.bundle/Tweaks.png"] forKey:@"iconImage"];
				[specifiers addObject:cydiaSpecifier];
			}
		}
		if (shouldShowAppStoreApps) {
			if (AppStoreAppSpecifiers.count > 0) {
				[specifiers removeObjectsInArray:AppStoreAppSpecifiers];
				[AppStoreAppSpecifiers removeObjectAtIndex:0];
				PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:appStoreAppsLabel target:self set:NULL get:NULL detail:[AppStoreAppSpecifiersController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
				[appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore" format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
				[specifiers addObject:appstoreSpecifier];
			}
		}
		PO2Log([NSString stringWithFormat:@"savedSpecifiers = %@", savedSpecifiers], shouldSyslogSpam);
	});
	PO2Log([NSString stringWithFormat:@"shuffledSpecifiers = %@", specifiers], shouldSyslogSpam);
	return specifiers;
}

-(void) refresh3rdPartyBundles {
	%orig();
	NSMutableArray *savedSpecifiers = [NSMutableArray array];
	BOOL go = 0;
	for (PSSpecifier *s in MSHookIvar<NSMutableArray *>(self, "_specifiers")) {
		if (!go && [s.identifier isEqualToString:@"App Store"]) {
			go = 1;
			continue;
		}
		if (go) {
			[savedSpecifiers addObject:s];
		}
	}
	for (PSSpecifier *s in savedSpecifiers) {
		[self removeSpecifier:s];
	}
	[savedSpecifiers removeObjectAtIndex:0];
	[AppStoreAppSpecifiers release];
	AppStoreAppSpecifiers = [savedSpecifiers retain];
}

-(void) reloadSpecifiers {
	return;
}
%end
%end

%hook PreferencesAppController
%new
-(void) preferenceOrganizerOpenTweakPane:(NSString *)name {
	// this is where I'd put a method
	// if I had one
}
// Parses the given URL to check if it's in a PreferenceOrganizer2-API conforming format, that is to say,
// it has a root=Tweaks, and a &path= corresponding to a tweak name. At the moment, simply strips the URL
// and launches Preferences into the Tweaks pane (even if they've renamed it), since the method by which
// Apple discovers and pushes PSListControllers by name (Info.plist information) is still unknown.
-(void) applicationOpenURL:(NSURL *)url {
	NSString *parsableURL = [url absoluteString];
	if (parsableURL.length >= 11 && [parsableURL rangeOfString:@"root=Tweaks"].location != NSNotFound) {
		NSString *truncatedPrefsURL = [@"prefs:root=" stringByAppendingString:tweaksLabel];
		url = [NSURL URLWithString:truncatedPrefsURL];
		%orig(url);
		NSRange tweakPathRange = [parsableURL rangeOfString:@"path="];
		if (tweakPathRange.location != NSNotFound) {
			NSInteger tweakPathOrigin = tweakPathRange.location + tweakPathRange.length;
			[self preferenceOrganizerOpenTweakPane:[parsableURL substringWithRange:NSMakeRange(tweakPathOrigin, parsableURL.length - tweakPathOrigin)]];
		}
	} else {
		%orig(url);
	}
}
%end

%ctor {
	PO2Log([NSString stringWithFormat:@"kCFCoreFoundationVersionNumber = %f", kCFCoreFoundationVersionNumber], shouldSyslogSpam);
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
		%init(iOS7Up, PrefsListController = objc_getClass((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) ? "PSUIPrefsListController" : "PrefsListController"));
	} else {
		%init(iOS6);
	}
	%init();
	PO2InitPrefs();
	PO2Observer(PO2InitPrefs, "net.angelxwind.preferenceorganizer2-PreferencesChanged");
}
