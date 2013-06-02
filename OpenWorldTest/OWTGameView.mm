//
//  SKRGameView.m
//  OpenWorldTest
//
//  Created by Steven Troughton-Smith on 23/12/2012.
//  Copyright (c) 2012 High Caffeine Content. All rights reserved.
//

/*
 
	Check OpenWorldTest-Prefix.pch for constants
 
 */

#import "OWTGameView.h"
#import "DDHidLib.h"
#import "OWTPlayer.h"
#import "OWTChunk.h"
#import "OWTLevelGenerator.h"

#import "OVR.h"
#import "SKROculus.h"
#import <GLKit/GLKMath.h>
#import "SKRHydra.h"

// Standard units.
CGFloat const kGravityAcceleration = 0;//-9.80665;
CGFloat const kJumpHeight = 1.5;
CGFloat const kPlayerMovementSpeed = 1.4;

SCNGeometry *dirtGeometry;
SCNGeometry *grassGeometry;
SCNGeometry *waterGeometry;
SCNGeometry *treeGeometry;

@interface OWTGameView () <SKRHydraDelegate>
{
    SKRHydra *hydra;

    CGLContextObj cglContext1;
    CGLContextObj cglContext2;
    CGLPixelFormatObj cglPixelFormat;
    NSOpenGLContext *leftEyeContext;
    NSOpenGLContext *rightEyeContext;
    
    SCNNode *terrainParentNode;
    
    GLKVector3 keyboardMovementDirection;
}

@end

@implementation OWTGameView

-(void)initCrosshairs
{
	crosshairLayer = [CALayer layer];
	crosshairLayer.contents = (id)[NSImage imageNamed:@"crosshair.png"];
	crosshairLayer.bounds = CGRectMake(0, 0, 40., 40.);
	crosshairLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	
	[self.layer addSublayer:crosshairLayer];
}


-(void)initFPSLabel
{
	
	frameRateLabel = [CATextLayer layer];
	frameRateLabel.anchorPoint = CGPointZero;
	frameRateLabel.position = CGPointZero;
	frameRateLabel.bounds = CGRectMake(0, 0, 100, 23);
	frameRateLabel.foregroundColor = [[NSColor whiteColor] CGColor];
	frameRateLabel.font = (__bridge CFTypeRef)([NSFont boldSystemFontOfSize:6]) ;
	frameRateLabel.fontSize = 16;
	
	[self.layer addSublayer:frameRateLabel];
}

#pragma mark - DisplayLink

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime,
									CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext){
	return [(__bridge OWTGameView *)displayLinkContext gameLoopAtTime:*inOutputTime];
}

-(void)setupLink
{
	if (CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef) == kCVReturnSuccess){
		CVDisplayLinkSetOutputCallback(displayLinkRef, DisplayLinkCallback, (__bridge void *)(self));
		[self setRunning:YES];
	}
}

-(void)setRunning:(BOOL)running
{
	if (gameLoopRunning != running){
		gameLoopRunning = running;
		
		if (gameLoopRunning){
			CVDisplayLinkStart(displayLinkRef);
		}
		else
		{
			CVDisplayLinkStop(displayLinkRef);
		}
	}
}

CVTimeStamp oldTime;

CVTimeStamp lastChunkTick;

- (CVReturn)gameLoopAtTime:(CVTimeStamp)time {    
	if (time.hostTime-oldTime.hostTime < (NSEC_PER_MSEC))
		return kCVReturnSuccess;
    
    SCNVector4 oculusRotation = [self.oculus poll];
    SKRHydraControllerPair controllers = [hydra poll];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		CGFloat refreshPeriod = CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLinkRef);
		
		[playerNode setAcceleration:SCNVector3Make(0, 0, kGravityAcceleration)];
		[playerNode updatePositionWithRefreshPeriod:refreshPeriod];
		
		[playerNode checkCollisionWithNodes:blocks];
				
		oldTime = time;
		
        // Update arms with hydra controllers
        [playerNode updateArm:SKRLeft
                     position:controllers.left.position
                     rotation:controllers.left.rotation];
        [playerNode updateArm:SKRRight
                     position:controllers.right.position
                     rotation:controllers.right.rotation];

        if ([self.oculus deviceAvailable])
        {
            playerNode.rotation = oculusRotation;
        }
        
        playerNode.movementDirection = GLKVector3Add(keyboardMovementDirection,
                                                     GLKVector3Make(controllers.left.joystick.x,
                                                                    0,
                                                                    -controllers.left.joystick.y));
                                                     
		if (time.hostTime-lastChunkTick.hostTime > (NSEC_PER_SEC*1))
		{
			lastChunkTick = time;
			[self loadChunksAroundPlayerPosition];
		}
	});
    
	return kCVReturnSuccess;
}

#pragma mark -
-(void)awakeFromNib
{
//    hydra = [[SKRHydra alloc] init];
//    hydra.delegate = self;
    self.oculus = [[SKROculus alloc] init];

    blocks = @[].mutableCopy;
	chunkCache = @{}.mutableCopy;
	
	[self premakeMaterials];
	[self setWantsLayer:YES];
	   
	SCNScene *scene = [SCNScene scene];
    self.scene = scene;

    terrainParentNode = [SCNNode node];
//    GLKQuaternion terrainOrientation = GLKQuaternionMakeWithMatrix3(GLKMatrix3MakeRotation(-M_PI_2, 1, 0, 0));
//    terrainParentNode.rotation = SKRVector4FromQuaternion(terrainOrientation.x, terrainOrientation.y, terrainOrientation.z, terrainOrientation.w);
    [scene.rootNode addChildNode:terrainParentNode];
    
    playerNode = [OWTPlayer nodeWithHMDInfo:[self.oculus hmdInfo]];
    playerNode.position = SCNVector3Make(MAP_BOUNDS/2, MAP_BOUNDS/2, 5);
    //	playerNode.position = SCNVector3Make(MAP_BOUNDS/2, 5, MAP_BOUNDS/2);
    //	playerNode.position = SCNVector3Make(0, 10, 0);
    [scene.rootNode addChildNode:playerNode];
    
    CGLPixelFormatAttribute attribs[] = {
        kCGLPFADepthSize, (CGLPixelFormatAttribute)24,
        kCGLPFAAccelerated,
        kCGLPFACompliant,
        kCGLPFAMPSafe,
        (CGLPixelFormatAttribute)0
    };
    GLint numPixelFormats = 0;
    CGLChoosePixelFormat (attribs, &cglPixelFormat, &numPixelFormats);
    
    CGLCreateContext(cglPixelFormat, NULL, &cglContext1);
    CGLCreateContext(cglPixelFormat, cglContext1, &cglContext2);
    
    float leftEyeWidth = [self.oculus deviceAvailable] ? self.bounds.size.width / 2 : self.bounds.size.width;
    NSRect leftEyeFrame = NSMakeRect(0, 0, leftEyeWidth, self.bounds.size.height);
    self.leftEyeView = [[SCNView alloc] initWithFrame:leftEyeFrame];
    leftEyeContext = [[NSOpenGLContext alloc] initWithCGLContextObj:cglContext1];
    self.leftEyeView.openGLContext = leftEyeContext;
    self.leftEyeView.scene = scene;
    [self addSubview:self.leftEyeView];
    [self.leftEyeView.layer setValue:@"left" forKey:@"eye"];
    [self.leftEyeView setPointOfView:playerNode.leftEye];
    
    if ([self.oculus deviceAvailable])
    {
        NSRect rightEyeFrame = NSMakeRect(self.bounds.size.width / 2, 0, self.bounds.size.width / 2, self.bounds.size.height);
        self.rightEyeView = [[SCNView alloc] initWithFrame:rightEyeFrame];
        rightEyeContext = [[NSOpenGLContext alloc] initWithCGLContextObj:cglContext2];
        self.rightEyeView.openGLContext = rightEyeContext;
        self.rightEyeView.scene = scene;
        [self addSubview:self.rightEyeView];
        [self.rightEyeView.layer setValue:@"right" forKey:@"eye"];
        [self.rightEyeView setPointOfView:playerNode.rightEye];
    }
    
    [self initFPSLabel];
    //	[self initCrosshairs];
    
	[self reload:self];

	[self becomeFirstResponder];
	[self startWatchingJoysticks];
	
	[self setupLink];
	
	SCNLight *sunlight = [SCNLight light];
	sunlight.type = SCNLightTypeDirectional;
	scene.rootNode.light = sunlight;
}

-(void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	crosshairLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

BOOL canReload = YES;

-(IBAction)reload:(id)sender
{
	if (!canReload)
		return;
	
	[blocks removeAllObjects];
	
	for (OWTChunk *chunk in terrainParentNode.childNodes)
	{
		if (![chunk isKindOfClass:[OWTChunk class]])
			continue;
		[chunk performSelector:@selector(removeFromParentNode)];
	}
	
	[chunkCache removeAllObjects];
	
	gen = [[OWTLevelGenerator alloc] init];
	
	[gen gen:12];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		canReload = NO;
		[self loadChunksAroundPlayerPosition];
		canReload = YES;
	});
	
}

#pragma mark - Map Generation

-(void)generateChunk:(CGPoint)chunkCoord
{
	OWTChunk *chunk = [chunkCache objectForKey:NSStringFromPoint(chunkCoord)];
	SCNScene *scene = self.scene;
	
	if (!chunk)
	{
		chunk = [[OWTChunk alloc] init];
		chunk.chunkX = chunkCoord.x;
		chunk.chunkY = chunkCoord.y;
		chunk.name = [NSString stringWithFormat:@"chunk:%@", NSStringFromPoint(chunkCoord)];
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			
			CGPoint position = chunkCoord;
			
			position.x *= CHUNK_SIZE;
			position.y *= CHUNK_SIZE;
			
			for (int y = position.y; y < position.y+CHUNK_SIZE; y++)
			{
				for (int x = position.x; x < position.x+CHUNK_SIZE; x++)
				{
					int maxZ = [gen valueForX:x Y:y]/GAME_DEPTH;
					
					for (int z = 0; z <= maxZ; z++)
					{
						SKRBlockType blockType = SKRBlockTypeGrass;
						
						if (z == 0 && z == maxZ)
							blockType = SKRBlockTypeWater;
						
						else if (z < 2 && z == maxZ)
							blockType = SKRBlockTypeDirt;
						
						if (z > 3 && z == maxZ)
							blockType = SKRBlockTypeTree;

						if (z >= 0 && z == maxZ)
							[self addBlockAtLocation:SCNVector3Make(x, y, z) inNode:chunk withType:blockType];
					}
				}
			}
		});
		
		[chunkCache setObject:chunk forKey:NSStringFromPoint(chunkCoord)];
	}
	
	if (!chunk.parentNode)
	{
		/* Animate the chunk into position */
		
		SCNVector3 cp = chunk.position;
		chunk.opacity = 0;
		cp.z = -4;
		chunk.position = cp;
		cp.z = 0;
		[terrainParentNode addChildNode:chunk];
		
		[SCNTransaction begin];
		[SCNTransaction setAnimationDuration:0.5];
		chunk.opacity = 1;
		chunk.position = cp;
		[SCNTransaction commit];
	}
}

-(void)loadChunksAroundPlayerPosition
{
	CGPoint playerChunk = CGPointMake(round(playerNode.position.x/CHUNK_SIZE), round(playerNode.position.y/CHUNK_SIZE));
	
	if (playerChunk.x > 2)
		playerChunk.x -= 2;
	if (playerChunk.y > 2)
		playerChunk.y -= 2;
	
	for (int j = 0; j < 4; j++)
	{
		for (int i = 0; i < 4; i++)
		{
			CGPoint newChunk;
			newChunk.x = playerChunk.x+i;
			newChunk.y = playerChunk.y+j;
			
			[self generateChunk:newChunk];
		}
	}
	
	/* Now unload chunks away from the player */
	
	for (OWTChunk *chunk in terrainParentNode.childNodes)
	{
		if (![chunk isKindOfClass:[OWTChunk class]])
			continue;
		
		double chunkDistance = sqrt(pow((playerChunk.x-chunk.chunkX),2)+pow((playerChunk.y-chunk.chunkY),2));
		
		if (chunkDistance > 4)
		{
			[chunk performSelector:@selector(removeFromParentNode) withObject:nil afterDelay:0.0];
		}
	}
}


-(SCNMaterial *)generateMaterialForBlockType:(SKRBlockType)type
{
	SCNMaterial *material = [SCNMaterial material];

	switch (type) {
		case SKRBlockTypeGrass:
			material.diffuse.contents = [NSImage imageNamed:@"grass.png"];
			break;
		case SKRBlockTypeWater:
		{
			material.diffuse.contents = [NSImage imageNamed:@"water.png"];
			material.transparency = 0.9;
			break;
		}
		case SKRBlockTypeDirt:
			material.diffuse.contents = [NSImage imageNamed:@"dirt.png"];
			break;
		case SKRBlockTypeTree:
		{
			material.diffuse.contents = [NSColor colorWithCalibratedRed:0.001 green:0.352 blue:0.001 alpha:1.000];
			break;
		}
		default:
			break;
	}
	
	material.diffuse.wrapS = SCNRepeat;
	material.diffuse.wrapT = SCNRepeat;
	material.diffuse.magnificationFilter = SCNNearestFiltering;
	material.doubleSided = NO;
	
	material.diffuse.contentsTransform = CATransform3DMakeScale(4, 4, 4);
	
	return material;
}

-(void)premakeMaterials
{
	/* Blocks */
	
	/* 
		We share the same scene for the different blocks, but copy the geometry
		for each kind. Each geometry has its own texture it shares with blocks
		of same type.
	 */
	
	NSString *cubePath = [[NSBundle mainBundle] pathForResource:@"cube" ofType:@"dae"];
	SCNScene *cubeScene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:cubePath] options:nil error:nil];
	
	SCNNode *cubeNode = [cubeScene.rootNode childNodeWithName:@"cube" recursively:NO];
	
	dirtGeometry = cubeNode.geometry.copy;
	dirtGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeDirt]];
	
	grassGeometry = cubeNode.geometry.copy;
	grassGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeGrass]];
	
	waterGeometry = cubeNode.geometry.copy;
	waterGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeWater]];
	
	/* Trees */
	
	NSString *treePath = [[NSBundle mainBundle] pathForResource:@"tree" ofType:@"dae"];
	SCNScene *treeScene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:treePath] options:nil error:nil];
	
	SCNNode *treeNode = [treeScene.rootNode childNodeWithName:@"tree" recursively:NO];
	
	treeGeometry = treeNode.geometry;
	treeGeometry.materials = @[[self generateMaterialForBlockType:SKRBlockTypeTree]];
	
}

-(void)addBlockAtLocation:(SCNVector3)location inNode:(SCNNode *)node withType:(SKRBlockType)type
{
	SCNGeometry *geometry = nil;
	
	switch (type) {
		case SKRBlockTypeGrass:
		{
			geometry = grassGeometry;
			break;
		}
		case SKRBlockTypeWater:
		{
			geometry = waterGeometry;
			break;
		}
		case SKRBlockTypeDirt:
		{
			geometry = dirtGeometry;
			break;
		}
		case SKRBlockTypeTree:
		{
			geometry = treeGeometry;
			break;
		}
			
		default:
			break;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		SCNNode *boxNode = [SCNNode nodeWithGeometry:geometry];
		boxNode.position = SCNVector3Make(location.x, location.y, location.z);
		[node addChildNode:boxNode];
        node.rendererDelegate = self;
		[blocks addObject:boxNode];
	});
}

#pragma mark - Input

-(BOOL)canBecomKeyView
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                  playerNode.rotation.x,
                                                                  playerNode.rotation.y,
                                                                  playerNode.rotation.z);
    float sensitivity = 0.003;
    GLKQuaternion xMouseRotation = GLKQuaternionMakeWithAngleAndAxis(-theEvent.deltaX * sensitivity, 0, 1, 0);
    GLKQuaternion yMouseRotation = GLKQuaternionMakeWithAngleAndAxis(-theEvent.deltaY * sensitivity, 1, 0, 0);
    GLKQuaternion newOrientation = GLKQuaternionMultiply(GLKQuaternionMultiply(orientation, yMouseRotation), xMouseRotation);
    playerNode.rotation = SKRVector4FromQuaternion(newOrientation.x,
                                                   newOrientation.y,
                                                   newOrientation.z,
                                                   newOrientation.w);
    
}

-(void)keyDown:(NSEvent *)theEvent
{
    if (theEvent.keyCode == 126)
    {
        playerNode.interpupillaryDistance += 0.01;
    }
	else if (theEvent.keyCode == 125)
    {
        playerNode.interpupillaryDistance -= 0.01;
    }

    if (theEvent.isARepeat)
    {
        return;
    }
    
    GLKVector3 newMovementDirection = keyboardMovementDirection;
    
    if (theEvent.keyCode == 13)
    {
        GLKVector3 forwardVector = GLKVector3Make(0.0, 0.0, -1.0);
        newMovementDirection = GLKVector3Add(newMovementDirection, forwardVector);
    }
	else if (theEvent.keyCode == 1)
    {
        GLKVector3 backwardVector = GLKVector3Make(0.0, 0.0, 1.0);
        newMovementDirection = GLKVector3Add(newMovementDirection, backwardVector);
    }
	else if (theEvent.keyCode == 0)
    {
        GLKVector3 leftVector = GLKVector3Make(-1.0, 0.0, 0.0);
        newMovementDirection = GLKVector3Add(newMovementDirection, leftVector);
    }
	else if (theEvent.keyCode == 2)
    {
        GLKVector3 rightVector = GLKVector3Make(1.0, 0.0, 0.0);
        newMovementDirection = GLKVector3Add(newMovementDirection, rightVector);
    }
    
    keyboardMovementDirection = newMovementDirection;
    
	if (theEvent.keyCode == 49 && playerNode.touchingGround)
	{
		
		// v^2 = u^2 + 2as
		// 0 = u^2 + 2as (v = 0 at top of jump)
		// -u^2 = 2as;
		// u^2 = -2as;
		// u = sqrt(-2 * kGravityAcceleration * kJumpHeight)
		
		[self jump];
	}
}

-(void)keyUp:(NSEvent *)theEvent
{
    GLKVector3 newMovementDirection = keyboardMovementDirection;
    
    if (theEvent.keyCode == 13)
    {
        GLKVector3 forwardVector = GLKVector3Make(0.0, 0.0, -1.0);
        newMovementDirection = GLKVector3Subtract(newMovementDirection, forwardVector);
    }
	else if (theEvent.keyCode == 1)
    {
        GLKVector3 backwardVector = GLKVector3Make(0.0, 0.0, 1.0);
        newMovementDirection = GLKVector3Subtract(newMovementDirection, backwardVector);
    }
	else if (theEvent.keyCode == 0)
    {
        GLKVector3 leftVector = GLKVector3Make(-1.0, 0.0, 0.0);
        newMovementDirection = GLKVector3Subtract(newMovementDirection, leftVector);
    }
	else if (theEvent.keyCode == 2)
    {
        GLKVector3 rightVector = GLKVector3Make(1.0, 0.0, 0.0);
        newMovementDirection = GLKVector3Subtract(newMovementDirection, rightVector);
    }
    
    keyboardMovementDirection = newMovementDirection;
    
	if (theEvent.keyCode == 49 && playerNode.touchingGround)
	{
		
		// v^2 = u^2 + 2as
		// 0 = u^2 + 2as (v = 0 at top of jump)
		// -u^2 = 2as;
		// u^2 = -2as;
		// u = sqrt(-2 * kGravityAcceleration * kJumpHeight)
		
		[self jump];
	}
}

- (void)jump
{
	SCNVector3 playerNodeVelocity = playerNode.velocity;
	playerNodeVelocity.z = sqrtf(-2 * kGravityAcceleration * kJumpHeight);
	[playerNode setVelocity:playerNodeVelocity];
}

#pragma mark - Hydra input
- (void)leftBumperPressed:(BOOL)pressed {
    if (!pressed) {
        return;
    }
    static SCNBox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        box = [SCNBox boxWithWidth:0.3 height:0.3 length:0.3 chamferRadius:0];
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor purpleColor];
        box.materials = @[material];
    });

    SCNNode *shapeNode = [SCNNode nodeWithGeometry:box];
    shapeNode.transform = playerNode.leftHand.worldTransform;
    
    [self.scene.rootNode addChildNode:shapeNode];
}

- (void)rightBumperPressed:(BOOL)pressed {
    if (!pressed) {
        return;
    }
    
    static SCNSphere *sphere;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sphere = [SCNSphere sphereWithRadius:0.3];
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor orangeColor];
        sphere.materials = @[material];
    });
    
    SCNNode *shapeNode = [SCNNode nodeWithGeometry:sphere];
    shapeNode.transform = playerNode.rightHand.worldTransform;
    
    [self.scene.rootNode addChildNode:shapeNode];
}

#pragma mark - Joystick input

/*
 
 Xbox Controller Mapping
 
 */

#define ABUTTON  0
#define BBUTTON  1
#define XBUTTON  2
#define YBUTTON  3


- (void)startWatchingJoysticks
{
	joysticks = [DDHidJoystick allJoysticks] ;
	
	if ([joysticks count]) // assume only one joystick connected
	{
		[[joysticks lastObject] setDelegate:self];
		[[joysticks lastObject] startListening];
	}
}
- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonDown:(unsigned)buttonNumber
{
	NSLog(@"JOYSTICK = %i", buttonNumber);
	
	if (buttonNumber == XBUTTON)
	{
		
	}
	
	if (buttonNumber == ABUTTON)
	{
		[self jump];
	}
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonUp:(unsigned)buttonNumber
{
	if (buttonNumber == XBUTTON)
	{
		
		
	}
}

int lastStickX = 0;
int lastStickY = 0;


- (void) ddhidJoystick: (DDHidJoystick *) joystick
				 stick: (unsigned) stick
			 otherAxis: (unsigned) otherAxis
		  valueChanged: (int) value;
{
	value/=SHRT_MAX/4;
	
	if (stick == 1)
	{
		
		if (otherAxis == 0)
			
			input.look.x = value;
		else
			input.look.y = value;
		
	}
	
	
}

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
				 stick: (unsigned) stick
			  xChanged: (int) value;
{
	value/=SHRT_MAX;
	
	lastStickX = value;
	
	if (abs(lastStickY) > abs(lastStickX))
		return;
	
	SCNVector4 movement;// = playerNode.movement;
	CGFloat delta = 4.;
	
	
	if (value == 0)
	{
		player.moving = NO;
		
		movement.y = 0;
		movement.w = 0;		
		
		input.left = NO;
		input.right = NO;
	}
	else
	{
		input.forward = NO;
		input.backward = NO;
		
		movement.x = 0;
		movement.z = 0;
		
		if (value > 0 )
		{
			input.right = YES;
			movement.w = delta;
		}
		else if (value < 0 )
		{
			input.left = YES;
			movement.y = delta;
		}
		
		player.moving =YES;
	}
	
//	[playerNode setMovement:movement];
	
}

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
				 stick: (unsigned) stick
			  yChanged: (int) value;
{
	value/=SHRT_MAX;
	CGFloat delta = 4.;
	
	SCNVector4 movement;// = playerNode.movement;
	
	lastStickY = value;
	
	if (abs(lastStickY) < abs(lastStickX))
		return;
	
	if (value == 0)
	{
		player.moving = NO;
		input.forward = NO;
		input.backward = NO;
		
		movement.x = 0;
		movement.z = 0;
	}
	else
	{
		input.left = NO;
		input.right = NO;
		
		movement.y = 0;
		movement.w = 0;
		
		if (value > 0 )
		{
			
			input.backward = YES;
			movement.z = delta;
			
		}
		else if (value < 0 )
		{
			input.forward = YES;
			movement.x = delta;
		}
		
		player.moving = YES;
	}
	
//	[playerNode setMovement:movement];
	
}

#pragma mark - FPS Label

NSDate *nextFrameCounterReset;
NSUInteger frameCount;

- (void)renderer:(id<SCNSceneRenderer>)aRenderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    // Only do movement for the left eye camera, since in stereo mode this will get called twice per frame (once for each eye)
    // and we only want to move once per frame
    if ([aRenderer.pointOfView isEqual:playerNode.leftEye])
    {
        GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                      playerNode.rotation.x,
                                                                      playerNode.rotation.y,
                                                                      playerNode.rotation.z);
        GLKVector3 position = GLKVector3Make(playerNode.position.x,
                                             playerNode.position.y,
                                             playerNode.position.z);
        float speed = 0.1;
        GLKVector3 rotatedVector = GLKQuaternionRotateVector3(orientation, playerNode.movementDirection);
        GLKVector3 translation = GLKVector3MultiplyScalar(rotatedVector, speed);
        GLKVector3 newPosition = GLKVector3Add(position, translation);
        playerNode.position = SCNVector3Make(newPosition.x,
                                             newPosition.y,
                                             newPosition.z);
    }
}

- (void)renderer:(id <SCNSceneRenderer>)aRenderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    // Only do fps update for the left eye camera, since in stereo mode this will get called twice per frame (once for each eye)
    if ([aRenderer.pointOfView isEqual:playerNode.leftEye])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSDate *now = [NSDate date];
            
            if (nextFrameCounterReset) {
                if (NSOrderedDescending == [now compare:nextFrameCounterReset]) {
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    frameRateLabel.string = [NSString stringWithFormat:@"%ld fps", frameCount];
                    [CATransaction commit];
                    frameCount = 0;
                    nextFrameCounterReset = [now dateByAddingTimeInterval:1.0];
                }
            } else {
                nextFrameCounterReset = [now dateByAddingTimeInterval:1.0];
            }
            
            ++frameCount;
        });
    }
}


@end
