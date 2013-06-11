//
//  SKRAppDelegate.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRView.h"
#import "SKROculus.h"
#import "SKRStereoEffect.h"

#import "SKRAppDelegate.h"

@implementation SKRAppDelegate
{
    NSWindow *_window;
    SKRView *_view;
    SKRStereoEffect *_stereoEffect;
    NSTrackingArea *_trackingArea;
}

- (id)initWithWindow:(NSWindow *)window skrView:(SKRView *)view worldGenerator:(NSObject<SKRWorldGenerator>*)worldGenerator
{
    self = [self init];
    if (self)
    {
        _window = window;
        _view = view;
        
        [_view setWorldGenerator:worldGenerator];
        
        _view.leftEyeView.delegate = self;
        _view.rightEyeView.delegate = self;
        
        if ([_view.oculus deviceAvailable])
        {
            _stereoEffect = [[SKRStereoEffect alloc] initWithHMDInfo:[_view.oculus hmdInfo]];
        }
    }
    return self;
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
    NSRect screenCoordsFrame = [_window convertRectToScreen:windowCoordsFrame];
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
