#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#define NSLog(LogContents, ...) NSLog((@"PreferenceOrganizer 2: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#define PO2PreferencePath @"/User/Library/Preferences/net.angelxwind.preferenceorganizer2.plist"
#define PO2LogPath @"/var/tmp/net.angelxwind.preferenceorganizer2.log"

static bool PO2Log(NSString *string, bool enabled);
static bool PO2Log(NSString *string, bool enabled) {
	if (enabled) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *formattedString = [NSString stringWithFormat:@"%@", string];
		NSLog(@"%@", formattedString);
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:PO2LogPath];
		if (!fileHandle) {
			[[NSFileManager defaultManager] createFileAtPath:PO2LogPath contents:nil attributes:nil];
			fileHandle = [NSFileHandle fileHandleForWritingAtPath:PO2LogPath];
		}
		if (fileHandle) {
			if (![formattedString hasSuffix:@"\n"]) {
				formattedString = [formattedString stringByAppendingString:@"\n"];
			}
			@try {
				[fileHandle seekToEndOfFile];
				[fileHandle writeData:[formattedString dataUsingEncoding:NSUTF8StringEncoding]];
			}
			@catch (NSException *e) {
				NSLog(@"Failed to log to file! ━Σ(ﾟДﾟ|||)━ %@", e);
				return 0;
			}
			[fileHandle closeFile];
			return 1;
		} else {
			return 0;
		}
		[pool drain];
	} else {
		return 0;
	}
}

#define STRINGIFY_(x) #x
#define STRINGIFY(x) STRINGIFY_(x)

#define PO2BoolLog(arg) PO2Log([NSString stringWithFormat:@"%s = %d", #arg, arg], shouldSyslogSpam)
#define PO2BoolPref(var, key, default) do { \
	NSNumber *key = PO2Settings[@STRINGIFY(key)]; \
	var = key ? [key boolValue] : default; \
	PO2BoolLog(var); \
} while (0)

#define PO2IntLog(arg) PO2Log([NSString stringWithFormat:@"%s = %i", #arg, arg], shouldSyslogSpam)
#define PO2IntPref(var, key, default) do { \
	NSNumber *key = PO2Settings[@STRINGIFY(key)]; \
	var = key ? [key intValue] : default; \
	PO2IntLog(var); \
} while (0)

#define PO2FloatLog(arg) PO2Log([NSString stringWithFormat:@"%s = %f", #arg, arg], shouldSyslogSpam)
#define PO2FloatPref(var, key, default) do { \
	NSNumber *key = PO2Settings[@STRINGIFY(key)]; \
	var = key ? [key floatValue] : default; \
	PO2FloatLog(var); \
} while (0)

#define PO2StringLog(arg) PO2Log([NSString stringWithFormat:@"%s = %@", #arg, arg], shouldSyslogSpam)
#define PO2StringPref(var, key, default) do { \
	NSString *key = PO2Settings[@STRINGIFY(key)]; \
	var = ([key length] > 0) ? key : default; \
	PO2StringLog(var); \
} while (0)

#define PO2Observer(funcToCall, listener) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)funcToCall, CFSTR(listener), NULL, CFNotificationSuspensionBehaviorCoalesce);
#define PO2SyncPrefs() \
	NSLog(@"PreferenceOrganizer 2 (C) 2013-2015 Karen Tsai (angelXwind)"); \
	NSDictionary *PO2Settings = [NSDictionary dictionaryWithContentsOfFile:PO2PreferencePath];
#define isJonyIve() (kCFCoreFoundationVersionNumber > 793.00)

