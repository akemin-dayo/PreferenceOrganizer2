#import "PO2Log.h"

bool PO2Log(NSString *string, bool enabled) {
	if (enabled) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSLog(@"%@", string);
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:PO2LogPath];
		if (!fileHandle) {
			[[NSFileManager defaultManager] createFileAtPath:PO2LogPath contents:nil attributes:nil];
			fileHandle = [NSFileHandle fileHandleForWritingAtPath:PO2LogPath];
		}
		if (fileHandle) {
			if (![string hasSuffix:@"\n"]) {
				string = [string stringByAppendingString:@"\n"];
			}
			@try {
				[fileHandle seekToEndOfFile];
				[fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
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