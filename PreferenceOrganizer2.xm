#import "PreferenceOrganizer2.h"

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
static BOOL deviceShowsTVProviders = 0;
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
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
		shouldShowSocialApps = 0;
	} else {
		PO2BoolPref(shouldShowSocialApps, ShowSocialApps, 1);
	}
	karenLocalizer = [[KarenLocalizer alloc] initWithKarenLocalizerBundle:@"PreferenceOrganizer2"];
	PO2StringPref(appleAppsLabel, AppleAppsName, [karenLocalizer karenLocalizeString:@"APPLE_APPS"]);
	PO2StringPref(socialAppsLabel, SocialAppsName, [karenLocalizer karenLocalizeString:@"SOCIAL_APPS"]);
	PO2StringPref(tweaksLabel, TweaksName, [karenLocalizer karenLocalizeString:@"TWEAKS"]);
	PO2StringPref(appStoreAppsLabel, AppStoreAppsName, [karenLocalizer karenLocalizeString:@"APP_STORE_APPS"]);
}

void removeOldAppleThirdPartySpecifiers(NSMutableArray <PSSpecifier *> *specifiers) {
	NSMutableArray *itemsToDelete = [NSMutableArray array];
	for (PSSpecifier *spec in specifiers) {
		NSString *Id = spec.identifier;
		if ([Id isEqualToString:@"com.apple.news"] || [Id isEqualToString:@"com.apple.iBooks"] || [Id isEqualToString:@"com.apple.podcasts"] || [Id isEqualToString:@"com.apple.itunesu"]) {
			[itemsToDelete addObject:spec];
		}
	}
	[specifiers removeObjectsInArray:itemsToDelete];
}

void fixupThirdPartySpecifiers(PSListController *self, NSArray <PSSpecifier *> *thirdParty, NSDictionary *appleThirdParty) {
	// Then add all third party specifiers into correct categories
	// Also remove them from the original locations
	NSMutableArray *specifiers = [[NSMutableArray alloc] initWithArray:((PSListController *)self).specifiers];
	if (shouldShowAppleApps) {
		NSArray *appleThirdPartySpecifiers = [appleThirdParty allValues];
		removeOldAppleThirdPartySpecifiers(AppleAppSpecifiers);
		[AppleAppSpecifiers addObjectsFromArray:appleThirdPartySpecifiers];
		[specifiers removeObjectsInArray:appleThirdPartySpecifiers];
	}
	if (shouldShowAppStoreApps) {
		[AppStoreAppSpecifiers removeAllObjects];
		[AppStoreAppSpecifiers addObjectsFromArray:thirdParty];
		[specifiers removeObjectsInArray:thirdParty];
	}
	((PSListController *)self).specifiers = specifiers;
}

// For iOS 10
void removeOldAppleGroupSpecifiers(NSMutableArray <PSSpecifier *> *specifiers) {
	NSMutableArray *itemsToDelete = [NSMutableArray array];
	for (PSSpecifier *spec in specifiers) {
		NSString *specID = spec.identifier;
		if ([specID isEqualToString:@"APPLE_ACCOUNT_GROUP"] || [specID isEqualToString:@"ACCOUNTS_GROUP"] || [specID isEqualToString:@"MEDIA_GROUP"]) {
			[itemsToDelete addObject:spec];
		}
	}
	[specifiers removeObjectsInArray:itemsToDelete];
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
	if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) && !(MSHookIvar<NSArray *>(self, "_thirdPartySpecifiers"))) {
		return specifiers;
	}
	PO2InitPrefs();
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
		// NSLog(@"%@", specifiers);
		for (int i = 0; i < specifiers.count; i++) { // We can't fast enumerate when order matters
			PSSpecifier *s = (PSSpecifier *) specifiers[i];
			NSString *identifier = s.identifier ?: @"";

			// If we're not a group cell...
			if (s.cellType != 0) {
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
				else if ([identifier isEqualToString:(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) ? @"STORE" : @"CASTLE"] ) {
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
					// [newSavedGroup addObject:specifiers[i - 1]];
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
					// NSLog(@"currentOrganizableGroup = %@", currentOrganizableGroup);
					// NSLog(@"identifier = %@", identifier);
					if ([identifier isEqualToString:@"VIDEO_SUBSCRIBER_GROUP"]) {
						deviceShowsTVProviders = 1;
					}
					// If the DDI is mounted, groupIDs will all shift down by 1, causing the categories to be sorted incorrectly.
					// If an iOS 11 device is in a locale where the TV Provider option will show, groupID must be adjusted
					if (groupID < 2 + ddiIsMounted + deviceShowsTVProviders) {
						groupID++;
						currentOrganizableGroup = @"STORE";
					} else if (groupID == 2 + ddiIsMounted + deviceShowsTVProviders) {
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
				// NSLog(@"Adding %@ to %@", s.identifier, currentOrganizableGroup);
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
		AppleAppSpecifiers = [organizableSpecifiers[(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) ? @"STORE" : @"CASTLE"] retain];
		if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0) {
			[AppleAppSpecifiers addObjectsFromArray:organizableSpecifiers[@"STORE"]];
		}

		SocialAppSpecifiers = [organizableSpecifiers[@"SOCIAL_ACCOUNTS"] retain];

		NSMutableArray *tweaksGroup = organizableSpecifiers[@"TWEAKS"];
		if ([tweaksGroup count] != 0 && ((PSSpecifier *)tweaksGroup[0]).cellType == 0 && ((PSSpecifier *)tweaksGroup[1]).cellType == 0) {
			[tweaksGroup removeObjectAtIndex:0];
		}
		TweakSpecifiers = [tweaksGroup retain];

		AppStoreAppSpecifiers = [organizableSpecifiers[@"APPS"] retain];

		// Shuffling START!!
		// Make a group section for our special organized groups
		[specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
		
		if (shouldShowAppleApps && AppleAppSpecifiers) {
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0) {
				// Workaround for a bug in iOS 10
				// If all Apple groups (APPLE_ACCOUNT_GROUP, etc.) are deleted, it will crash
				for (PSSpecifier* specifier in AppleAppSpecifiers) {
					// We'll handle this later in insertMovedThirdPartySpecifiersAnimated
					if ([specifier.identifier isEqualToString:@"MEDIA_GROUP"] || [specifier.identifier isEqualToString:@"ACCOUNTS_GROUP"] || [specifier.identifier isEqualToString:@"APPLE_ACCOUNT_GROUP"]) {
						continue;
					} else {
						[specifiers removeObject:specifier];
					}
				}
			} else {
				// Original behaviour is fine in iOS 9
				[specifiers removeObjectsInArray:AppleAppSpecifiers];
			}
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

		if ((shouldShowAppleApps && AppleAppSpecifiers) && (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)) {
			// Move deleted group specifiers to the end...
			NSMutableArray *specifiersToRemove = [[NSMutableArray alloc] init];
			for (int i = 0; i < specifiers.count; i++) {
				PSSpecifier *specifier = (PSSpecifier *) specifiers[i];
				NSString *identifier = specifier.identifier ?: @"";
				// NSLog(@"specifier.identifier = %@",specifier.identifier);
				if ([specifier.identifier isEqualToString:@"MEDIA_GROUP"] || [specifier.identifier isEqualToString:@"ACCOUNTS_GROUP"] || [specifier.identifier isEqualToString:@"APPLE_ACCOUNT_GROUP"]) {
					// Move to the end only if DDI is mounted on iOS 10 (otherwise, the Settings app will crash for… some reason)
					// That being said, this fix DOES cause a minor layout issue where "Wallet and Apple Pay" ends up sticking to the bottom of the PreferenceOrganiser 2 group, so I'll need to find a better solution for this later
					if (((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)) && ddiIsMounted) {
						[specifiers removeObject:specifier];
						[specifiers addObject:specifier];
					} else {
						[specifiersToRemove addObject:specifier];
					}
				}
			}
			[specifiers removeObjectsInArray:specifiersToRemove];
		}
		PO2Log([NSString stringWithFormat:@"organizableSpecifiers = %@", organizableSpecifiers], shouldSyslogSpam);
	});
	
	// If we found Apple's third party apps, we really won't add them because this would mess up the UITableView row count check after the update
	if (shouldShowAppleApps) {
		[specifiers removeObjectsInArray:[MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues]];
	}
	
	PO2Log([NSString stringWithFormat:@"shuffledSpecifiers = %@", specifiers], shouldSyslogSpam);
	return specifiers;
}

// This method may add some Apple's third party specifiers with respect to restriction settings and results in duplicate entries, so fix it here
-(void) updateRestrictedSettings {
	%orig();
	if (shouldShowAppStoreApps) {
		[((PSListController *)self).specifiers removeObjectsInArray:[MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues]];
		removeOldAppleThirdPartySpecifiers(AppleAppSpecifiers);
		[AppleAppSpecifiers addObjectsFromArray:[MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues]];
	}
}

// Write custom -loadView method implementation that works with unorganised specifiers... which somehow fixes the infamous iOS 9.x iPad crash bug
// However, PreferenceLoader ultimately should be updated in order to fix the insertion bug present on iOS 9.x iPads, as stated by vit9696 (#9)
-(void) loadView {
	NSMutableArray *originalSpecifiers = MSHookIvar<NSMutableArray *>(self, "_specifiers");
	MSHookIvar<NSMutableArray *>(self, "_specifiers") = unorganisedSpecifiers;
	%orig();
	MSHookIvar<NSMutableArray *>(self, "_specifiers") = originalSpecifiers;
}
%end
%end

%hook PrefsListController
%group iOS9Up
// Redirect all of Apple's third party specifiers to AppleAppSpecifiers
-(void) insertMovedThirdPartySpecifiersAnimated:(BOOL)animated {
	if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0) && (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0) && (shouldShowAppleApps && AppleAppSpecifiers)) {
		// Appears to be the cause behind the resume-from-suspend crash on iOS 11 (as long as the _thirdPartySpecifiers condition in -(NSMutableArray *) specifiers is present)
		removeOldAppleGroupSpecifiers([self specifiers]);
	}
	if (shouldShowAppleApps && AppleAppSpecifiers.count) {
		NSArray <PSSpecifier *> *movedThirdPartySpecifiers = [MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues];
		removeOldAppleThirdPartySpecifiers(AppleAppSpecifiers);
		[AppleAppSpecifiers addObjectsFromArray:movedThirdPartySpecifiers];
	} else {
		%orig(animated);
	}
}

-(void) _reallyLoadThirdPartySpecifiersForProxies:(NSArray *)apps withCompletion:(void (^)(NSArray <PSSpecifier *> *thirdParty, NSDictionary *appleThirdParty))completion {
	// thirdParty - self->_thirdPartySpecifiers
	// appleThirdParty - self->_movedThirdPartySpecifiers
	void (^newCompletion)(NSArray <PSSpecifier *> *, NSDictionary *) = ^(NSArray <PSSpecifier *> *thirdParty, NSDictionary *appleThirdParty) {
		if (completion) {
			completion(thirdParty, appleThirdParty);
		}
		fixupThirdPartySpecifiers(self, thirdParty, appleThirdParty);
	};
	%orig(apps, newCompletion);
}

// iOS 10 renamed this method, should be benign hooking this on iOS 9 as it wouldn't exist
// Somewhat bad practice in that this is a literal copy-pasta of the above code, but this'll have to do for now until I figure out a better method of doing so
-(void) _reallyLoadThirdPartySpecifiersForApps:(NSArray *)apps withCompletion:(void (^)(NSArray <PSSpecifier *> *thirdParty, NSDictionary *appleThirdParty))completion {
	// thirdParty - self->_thirdPartySpecifiers
	// appleThirdParty - self->_movedThirdPartySpecifiers
	void (^newCompletion)(NSArray <PSSpecifier *> *, NSDictionary *) = ^(NSArray <PSSpecifier *> *thirdParty, NSDictionary *appleThirdParty) {
		if (completion) {
			completion(thirdParty, appleThirdParty);
		}
		fixupThirdPartySpecifiers(self, thirdParty, appleThirdParty);
	};
	%orig(apps, newCompletion);
}
%end

%group iOS78
-(void) insertMovedThirdPartySpecifiersAtStartIndex:(NSUInteger)index usingInsertBlock:(id)arg2 andExistenceBlock:(id)arg3 {
	if (shouldShowAppStoreApps && AppStoreAppSpecifiers.count) {
		[AppStoreAppSpecifiers removeObjectsInArray:[MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues]];
		[AppStoreAppSpecifiers addObjectsFromArray:[MSHookIvar<NSMutableDictionary *>(self, "_movedThirdPartySpecifiers") allValues]];
	} else {
		%orig(index, arg2, arg3);
	}
}

-(void) _reallyLoadThirdPartySpecifiersForProxies:(NSArray *)apps withCompletion:(void (^)())completion {
	void (^newCompletion)() = ^(void) {
		if (completion)
			completion();
		NSArray <PSSpecifier *> *thirdParty = MSHookIvar<NSArray <PSSpecifier *> *>(self, "_thirdPartySpecifiers");
		NSDictionary *appleThirdParty = MSHookIvar<NSDictionary *>(self, "_movedThirdPartySpecifiers");
		
		fixupThirdPartySpecifiers(self, thirdParty, appleThirdParty);
	};
	%orig(apps, newCompletion);
}

-(void) reloadSpecifiers {
	return;
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
	PO2InitPrefs();
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableDictionary *savedSpecifiers = [NSMutableDictionary dictionary];
		NSInteger group = -1;
		for (PSSpecifier *s in specifiers) {
			if (s.cellType == 0) {
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
// Push the requested tweak specifier controller.
-(BOOL) preferenceOrganizerOpenTweakPane:(NSString *)name {
	// Replace the percent escapes in an iOS 6-friendly way (deprecated in iOS 9).
	name = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// Set up return value.
	BOOL foundMatch = NO;
	
	// Loop the registered TweakSpecifiers.
	for (PSSpecifier *specifier in TweakSpecifiers) {
		// If we have a match, and that match has a non-nil target, let's do this.
		if ([name caseInsensitiveCompare:[specifier name]] == NSOrderedSame && [specifier target]) {
			// We have a valid match.
			foundMatch = YES;

			// Push the requested controller.
			[[[specifier target] navigationController] pushViewController:[[specifier target] controllerForSpecifier:specifier] animated:NO];
			
			// Get the specifier for TweaksSpecifier.
			PSSpecifier *tweaksSpecifier = [[[self rootController] rootListController] specifierForID:tweaksLabel];
			
			// If we got a specifier for TweaksSpecifier... 
			if (tweaksSpecifier) {
				// Get the TweakSpecifiersController.
				TweakSpecifiersController *tweakSpecifiersController = [[[self rootController] rootListController] controllerForSpecifier:tweaksSpecifier];
				
				// If we got a controller for TweakSpecifiers...
				if (tweakSpecifiersController) {
					// Get the navigation stack count.
					int stackCount = [[specifier target] navigationController].viewControllers.count;
				
					// Declare a NSMutableArray to manipulate the navigation stack (if necessary).
					NSMutableArray *mutableStack;
					// Switch on the navigation stack count and manipulate the stack accordingly.
					switch (stackCount) {
						// Three controllers in the navigation stack (rootListController, unknown controller, and controllerForSpecifier).
						// Check the controller at index 1 and replace it if necessary.
						case 3:
							// If the user was already on the TweakSpecifiersController, then we're good.
							if (![[[[specifier target] navigationController].viewControllers objectAtIndex:1] isMemberOfClass:[TweakSpecifiersController class]]) {
								// Get a mutable copy of the navigation stack.
								mutableStack = [NSMutableArray arrayWithArray:[[specifier target] navigationController].viewControllers];
								// Set the TweakSpecifiersController navigationItem title.
								[[tweakSpecifiersController navigationItem] setTitle: tweaksLabel];
								// Replace the intermediate controller with the TweakSpecifiersController.
								[mutableStack replaceObjectAtIndex:1 withObject:tweakSpecifiersController];
								// Update the navigation stack.
								[[specifier target] navigationController].viewControllers = [NSArray arrayWithArray:mutableStack];
								//NSLog(@"PO2: preferenceOrganizerOpenTweakPane: replace the intermediate controller with the TweakSpecifiersController.");
							}
							break;
						// Two controllers in the navigation stack (rootListController and controllerForSpecifier).
						// Insert the TweakSpecifiersController as an intermediate.
						case 2:
							// Get a mutable copy of the navigation stack.
							mutableStack = [NSMutableArray arrayWithArray:[[specifier target] navigationController].viewControllers];
							// Set the TweakSpecifiersController navigationItem title.
							[[tweakSpecifiersController navigationItem] setTitle: tweaksLabel];
							// Insert the TweakSpecifiersController as an intermediate controller.
							[mutableStack insertObject:tweakSpecifiersController atIndex: 1];
							// Update the navigation stack.
							[[specifier target] navigationController].viewControllers = [NSArray arrayWithArray:mutableStack];
							break;
						// One controller in the navigation stack should not be possible after we push the controllerForSpecifier,
						// and zero controllers is legitimately impossible.
						case 1:
						case 0:
							// Get out of here!
							break;
						// Too many controllers to manage.  Dump everything in the navigation stack except the first and last controllers.
						default:
							// Get a mutable copy of the navigation stack.
							mutableStack = [NSMutableArray arrayWithArray:[[specifier target] navigationController].viewControllers];
							// Remove everything in the middle.
							[mutableStack removeObjectsInRange:NSMakeRange(1, stackCount - 2)];
							// Set the TweakSpecifiersController navigationItem title.
							[[tweakSpecifiersController navigationItem] setTitle: tweaksLabel];
							// Insert the TweakSpecifiersController as an intermediate controller.
							[mutableStack insertObject:tweakSpecifiersController atIndex: 1];
							// Update the navigation stack.
							[[specifier target] navigationController].viewControllers = [NSArray arrayWithArray:mutableStack];
					}
				}
			}
			// Break the loop.
			break;
		}
	}
	// Return success or failure.
	return foundMatch;
}
// Parses the given URL to check if it's in a PreferenceOrganizer2-API conforming format, that is to say,
// it has a root=Tweaks, and a &path= corresponding to a tweak name.
// If %path= is present and it points to a valid tweak name, try to launch it.
// If preferenceOrganizerOpenTweakPane fails, just open the root tweak pane (even if they've renamed it).
-(void) applicationOpenURL:(NSURL *)url {
	NSString *parsableURL = [url absoluteString];
	if (parsableURL.length >= 11 && [parsableURL rangeOfString:@"root=Tweaks"].location != NSNotFound) {
		NSString *truncatedPrefsURL = [@"prefs:root=" stringByAppendingString:[tweaksLabel stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		url = [NSURL URLWithString:truncatedPrefsURL];
		NSRange tweakPathRange = [parsableURL rangeOfString:@"path="];
		if (tweakPathRange.location != NSNotFound) {
			NSInteger tweakPathOrigin = tweakPathRange.location + tweakPathRange.length;
			// If specified tweak was found, don't call the original method;
			if ([self preferenceOrganizerOpenTweakPane:[parsableURL substringWithRange:NSMakeRange(tweakPathOrigin, parsableURL.length - tweakPathOrigin)]]) {
				return;
			}
		}
	}
	%orig(url);
}
%end

%ctor {
	PO2Log([NSString stringWithFormat:@"kCFCoreFoundationVersionNumber = %f", kCFCoreFoundationVersionNumber], shouldSyslogSpam);
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
		%init(iOS7Up, PrefsListController = objc_getClass((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) ? "PSUIPrefsListController" : "PrefsListController"));
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
			%init(iOS9Up, PrefsListController = objc_getClass("PSUIPrefsListController"));
		} else {
			%init(iOS78);
		}
	} else {
		%init(iOS6);
	}
	%init();
	PO2InitPrefs();
	PO2Observer(PO2InitPrefs, "net.angelxwind.preferenceorganizer2-PreferencesChanged");
}
