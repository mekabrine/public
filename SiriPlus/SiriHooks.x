#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Reconstructed from original binary selectors, not verbatim decompiled source.
@interface SiriInterceptBridge : NSObject
+ (BOOL)isEnabled;
+ (BOOL)consume:(id)recognized controller:(UIViewController *)controller;
@end

%group SiriSpeech
%hook AFUISiriViewController
- (void)_tellSpeechDelegateSpeechRecognized:(id)recognition {
    %orig;
    @try {
        [SiriInterceptBridge consume:recognition controller:(UIViewController *)self];
    } @catch (NSException *exception) {
        NSLog(@"[SiriPlus] speech interception failed: %@", exception);
    }
}
%end
%end

%group SiriCommand
%hook AFConnection
- (void)_handleCommand:(id)command reply:(id)reply {
    %orig;
}
%end
%end

%ctor {
    @autoreleasepool {
        Class vc = objc_getClass("AFUISiriViewController");
        if (vc && class_getInstanceMethod(vc, @selector(_tellSpeechDelegateSpeechRecognized:))) {
            %init(SiriSpeech);
        }
        Class connection = objc_getClass("AFConnection");
        if (connection && class_getInstanceMethod(connection, @selector(_handleCommand:reply:))) {
            %init(SiriCommand);
        }
    }
}
