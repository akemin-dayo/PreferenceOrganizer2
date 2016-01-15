#define NSLog(LogContents, ...) NSLog((@"PreferenceOrganizer 2: %s:%d " LogContents), __FUNCTION__, __LINE__, ##__VA_ARGS__)
#define initKarenLocalize(bundlePath) NSBundle *karenBundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/KarenLocalize/%@.bundle",bundlePath]]
#define karenLocalizedString(key) [karenBundle localizedStringForKey:key value:@"" table:nil]