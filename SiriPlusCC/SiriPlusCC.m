#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/CCUIToggleModule.h>
#import <CoreFoundation/CoreFoundation.h>

@interface SiriPlusCC : CCUIToggleModule
@end
@implementation SiriPlusCC
- (NSString *)prefsPath { return @"/var/mobile/Library/Preferences/com.uckermark.siriplus.plist"; }
- (BOOL)isSelected {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:[self prefsPath]];
    return [prefs[@"tweakEnabled"] boolValue];
}
- (void)setSelected:(BOOL)selected {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[self prefsPath]] ?: [NSMutableDictionary dictionary];
    prefs[@"tweakEnabled"] = @(selected);
    if (![prefs writeToFile:[self prefsPath] atomically:YES]) NSLog(@"[SiriPlusCC] Failed to write to plist file.");
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.uckermark.siriplus"), NULL, NULL, YES);
    [self refreshState];
}
- (UIColor *)selectedColor { return [UIColor systemBlueColor]; }
@end
