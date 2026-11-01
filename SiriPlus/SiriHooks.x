#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Reconstructed selectors: original command suppression remains unknown.
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
        NSLog(@"[SiriPlus] interception error: %@", exception);
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
        Class speech = objc_getClass("AFUISiriViewController");
        if (speech && class_getInstanceMethod(speech, @selector(_tellSpeechDelegateSpeechRecognized:))) {
            %init(SiriSpeech);
        }
        Class commands = objc_getClass("AFConnection");
        if (commands && class_getInstanceMethod(commands, @selector(_handleCommand:reply:))) {
            %init(SiriCommand);
        }
    }
}
