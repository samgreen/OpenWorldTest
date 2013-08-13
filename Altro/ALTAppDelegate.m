//
//  ALTAppDelegate.m
//  Altro
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTAppDelegate.h"
#import "SKRAppDelegate.h"
#import "SKRPhysics.h"
#import "ALTWorldGenerator.h"
#import "ALTInputHandler.h"
#import "SKRView.h"

@implementation ALTAppDelegate
{
	IBOutlet NSView *_view;
    SKRAppDelegate *_skrAppDelegate;
    ALTInputHandler *_inputHandler;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    ALTWorldGenerator *worldGenerator = [[ALTWorldGenerator alloc] init];
    [SKRPhysics sharedInstance].friction = GLKVector3Make(0.5, 0.5, 0.1);

    _inputHandler = [[ALTInputHandler alloc] init];
    _skrAppDelegate = [[SKRAppDelegate alloc] initWithWindow:_window
                                                     skrView:(SKRView *)_view
                                              worldGenerator:worldGenerator
                                                inputHandler:_inputHandler];
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillBecomeActive:notification];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillResignActive:notification];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillTerminate:notification];
}

@end
