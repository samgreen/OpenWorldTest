//
//  SKRAppDelegate.m
//  OpenWorldTest
//
//  Created by Steven Troughton-Smith on 23/12/2012.
//  Copyright (c) 2012 High Caffeine Content. All rights reserved.
//

/*
 
	The following GL code was written by Thomas Goossens, one of the
	engineers behind SceneKit @ Apple. Thanks Thomas!
 
 */

#import "OWTAppDelegate.h"
#import "OWTGameView.h"
#import "SKROculus.h"
#import "SKRStereoEffect.h"

@implementation OWTAppDelegate
{
    SKRStereoEffect *_stereoEffect;
    NSTrackingArea *_trackingArea;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _view.leftEyeView.delegate = self;
    _view.rightEyeView.delegate = self;
    
    if ([_view.oculus deviceAvailable])
    {
        _stereoEffect = [[SKRStereoEffect alloc] initWithHMDInfo:[_view.oculus hmdInfo]];
    }
//    [_view enterFullScreenMode:[NSScreen mainScreen] withOptions:@{}];
    
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    [self setupMouseTracking];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self teardownMouseTracking];
}

- (void)setupMouseTracking
{
    if ([_view.oculus deviceAvailable])
    {
        return;
    }
    
    NSRect windowCoordsFrame = [_view.superview convertRect:_view.frame toView:nil];
    NSRect screenCoordsFrame = [self.window convertRectToScreen:windowCoordsFrame];
    NSPoint screenCoordsCenter = NSMakePoint(screenCoordsFrame.origin.x + _view.frame.size.width / 2,
                                             [NSScreen mainScreen].frame.size.height - (screenCoordsFrame.origin.y + screenCoordsFrame.size.height / 2));
    CGWarpMouseCursorPosition(screenCoordsCenter);
    
    CGAssociateMouseAndMouseCursorPosition(FALSE);
	
    [_view removeTrackingArea:_trackingArea];
	_trackingArea = [[NSTrackingArea alloc] initWithRect:_view.frame
                                                 options:(NSTrackingActiveInActiveApp | NSTrackingMouseMoved) owner:_view userInfo:nil];
	[_view addTrackingArea:_trackingArea];
    
    [NSCursor hide];
}

- (void)teardownMouseTracking
{
    CGAssociateMouseAndMouseCursorPosition(TRUE);

    [_view removeTrackingArea:_trackingArea];
    
    [NSCursor unhide];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_view setRunning:NO];
//    [_view exitFullScreenModeWithOptions:@{}];
}

// SCNView delegate
- (void)renderer:(id <SCNSceneRenderer>)aRenderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    [(id <SCNSceneRendererDelegate>)_stereoEffect renderer:aRenderer willRenderScene:scene atTime:time];
    [(id <SCNSceneRendererDelegate>)_view renderer:aRenderer willRenderScene:scene atTime:time];
}

- (void)renderer:(id <SCNSceneRenderer>)aRenderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
	[(id <SCNSceneRendererDelegate>)_stereoEffect renderer:aRenderer didRenderScene:scene atTime:time];
	[(id <SCNSceneRendererDelegate>)_view renderer:aRenderer didRenderScene:scene atTime:time];
}
@end
