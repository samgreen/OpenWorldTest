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

typedef struct _SKRPlayer
{
	BOOL moving;
	
} SKRPlayer;


typedef enum _SKRBlockType
{
	SKRBlockTypeWater,
	SKRBlockTypeDirt,
	SKRBlockTypeGrass,
	SKRBlockTypeTree
} SKRBlockType;

@class OWTPlayer;
@class OWTLevelGenerator;
@class SKROculus;

@interface OWTGameView : NSView <SCNSceneRendererDelegate, SCNProgramDelegate, SCNNodeRendererDelegate>
{
	
	NSMutableDictionary *chunkCache;
	CATextLayer *frameRateLabel;
	
	SKRInput input;
	SKRPlayer player;
	
	OWTPlayer *playerNode;
	NSMutableArray *blocks;
	NSArray *joysticks;
	OWTLevelGenerator *gen;
	NSTrackingArea * trackingArea;
	CVDisplayLinkRef displayLinkRef;
	
	BOOL gameLoopRunning;
	SCNNode *skyNode;
	SCNNode *floorNode;
	SCNNode *lastNode;
	
	CALayer *crosshairLayer;
}

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) IBOutlet SCNView *leftEyeView;
@property (nonatomic, strong) IBOutlet SCNView *rightEyeView;
@property (nonatomic, strong) SKROculus *oculus;

-(IBAction)reload:(id)sender;
- (CVReturn)gameLoopAtTime:(CVTimeStamp)time;
@end
