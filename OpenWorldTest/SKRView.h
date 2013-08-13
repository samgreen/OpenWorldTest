//
//  SKRGameView.h
//  OpenWorldTest
//
//  Created by Steven Troughton-Smith on 23/12/2012.
//  Copyright (c) 2012 High Caffeine Content. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import <OpenGL/gl.h>
#import "SKRWorldGenerator.h"
#import "SKRInputHandler.h"

typedef struct _SKRInput
{
	BOOL up;
	BOOL down;
	
	BOOL forward;
	BOOL backward;
	BOOL left;
	BOOL right;
	
	SCNVector3 look;
	
} SKRInput;

@class SKRPlayer;
@class SKROculus;

@interface SKRView : NSView <SCNSceneRendererDelegate, SCNProgramDelegate, SCNNodeRendererDelegate>
{
    CATextLayer *frameRateLabel;
	
	SKRInput input;
	
	SKRPlayer *playerNode;
	NSArray *joysticks;
	NSTrackingArea * trackingArea;
	CVDisplayLinkRef displayLinkRef;
	
	BOOL gameLoopRunning;
	
	CALayer *crosshairLayer;
}

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SCNView *leftEyeView;
@property (nonatomic, strong) SCNView *rightEyeView;
@property (nonatomic, strong) SKROculus *oculus;
@property (nonatomic, strong) NSObject<SKRInputHandler> *inputHandler;

-(CVReturn)gameLoopAtTime:(CVTimeStamp)time;
-(void)setRunning:(BOOL)running;
-(void)setWorldGenerator:(NSObject<SKRWorldGenerator>*)worldGenerator;

@end
