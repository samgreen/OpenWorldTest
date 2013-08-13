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

#import "SKRView.h"
#import "DDHidLib.h"
#import "SKRPlayer.h"
#import "SKRPhysics.h"

#import "OVR.h"
#import "SKROculus.h"
#import <GLKit/GLKMath.h>
#import "SKRHydra.h"
#import "ALTPointCloudMeshCreation.h"

@interface SKRView () <SKRHydraDelegate>
{
    SKRHydra *hydra;

    CGLContextObj cglContext1;
    CGLContextObj cglContext2;
    CGLPixelFormatObj cglPixelFormat;
    NSOpenGLContext *leftEyeContext;
    NSOpenGLContext *rightEyeContext;
    
    NSObject<SKRWorldGenerator> *_worldGenerator;
    SCNNode *_worldParentNode;
    
    GLKVector3 _keyboardMovementDirection;

    NSMutableArray *_creations;
    ALTPointCloudMeshCreation *_currentCreation;
    BOOL _mouseButtonDown;

    float _rollDirection;
}

@end

@implementation SKRView

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

#pragma mark - World generation

-(void)setWorldGenerator:(NSObject<SKRWorldGenerator>*)worldGenerator
{
    playerNode.position = [worldGenerator initialPlayerPosition];
    playerNode.rotation = [worldGenerator initialPlayerRotation];
    if ([worldGenerator playerShouldHaveLight])
    {
        SCNLight * light = [SCNLight light];
        [light setType:SCNLightTypeOmni];
        playerNode.light = light;
    }
    else
    {
        playerNode.light = nil;
    }
    _worldGenerator = worldGenerator;
}

#pragma mark - DisplayLink

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime,
									CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext){
	return [(__bridge SKRView *)displayLinkContext gameLoopAtTime:*inOutputTime];
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
    SCNVector4 oculusRotation = [self.oculus poll];
    SKRHydraControllerPair controllers = [hydra poll];
	
    // Update player
    // Update arms with hydra controllers
    [playerNode updateArm:SKRLeft
                 position:controllers.left.position
                 rotation:controllers.left.rotation];
    [playerNode updateArm:SKRRight
                 position:controllers.right.position
                 rotation:controllers.right.rotation];
    
    // Update rotation
    if ([self.oculus deviceAvailable])
    {
        playerNode.rotation = oculusRotation;
    }
    else
    {
        GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                      playerNode.rotation.x,
                                                                      playerNode.rotation.y,
                                                                      playerNode.rotation.z);
        float rollSpeed = 0.01;
        GLKQuaternion rollRotation = GLKQuaternionMakeWithAngleAndAxis(_rollDirection * rollSpeed, 0, 0, 1);
        GLKQuaternion newOrientation = GLKQuaternionMultiply(orientation, rollRotation);
        playerNode.rotation = SKRVector4FromQuaternion(newOrientation);
    }
    
    // Update movement
    playerNode.movementDirection = GLKVector3Add(_keyboardMovementDirection,
                                                 GLKVector3Make(controllers.left.joystick.x,
                                                                0,
                                                                -controllers.left.joystick.y));

    GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                  playerNode.rotation.x,
                                                                  playerNode.rotation.y,
                                                                  playerNode.rotation.z);
    float speed = 0.06;
    GLKVector3 rotatedVector = GLKQuaternionRotateVector3(orientation, playerNode.movementDirection);
    GLKVector3 translation = GLKVector3MultiplyScalar(rotatedVector, speed);
    playerNode.velocity = GLKVector3Add(playerNode.velocity, translation);

    if (_mouseButtonDown)
    {
        GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                      playerNode.rotation.x,
                                                                      playerNode.rotation.y,
                                                                      playerNode.rotation.z);
        GLKVector3 forwardVector = GLKVector3Make(0, 0, -1);
        GLKVector3 orientedForwardVector = GLKQuaternionRotateVector3(orientation, forwardVector);
        GLKVector3 scaledOrientedForwardVector = GLKVector3MultiplyScalar(orientedForwardVector, 5.0);
        
        GLKVector3 pointInFrontOfPlayer = GLKVector3Add(SCNVector3ToGLKVector3(playerNode.position), scaledOrientedForwardVector);
        [_currentCreation addSphereAtPoint:pointInFrontOfPlayer radius:0.2 numPoints:10];
    }
    
    // Update world
    if (time.hostTime-oldTime.hostTime < (NSEC_PER_MSEC))
		return kCVReturnSuccess;
    
	dispatch_async(dispatch_get_main_queue(), ^{
        
        if (time.hostTime-lastChunkTick.hostTime > (NSEC_PER_SEC*1))
		{
			lastChunkTick = time;
            [[_worldParentNode childNodes] enumerateObjectsUsingBlock:^(SCNNode *childNode, NSUInteger idx, BOOL *stop) {
                [childNode removeFromParentNode];
            }];
            SCNNode *worldNode = [_worldGenerator worldNodeForPlayerPosition:playerNode.position rotation:playerNode.rotation];
            [_worldParentNode addChildNode:worldNode];
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                if ([_worldGenerator respondsToSelector:@selector(updateAfterFirstAddedToParentNode)])
                {
                    [_worldGenerator updateAfterFirstAddedToParentNode];
                }
            });
		}
        
		NSTimeInterval deltaTime = CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLinkRef);
        [[SKRPhysics sharedInstance] updateEntity:playerNode inWorld:_worldGenerator deltaTime:deltaTime];
		
//		[playerNode checkCollisionWithNodes:blocks];
				
		oldTime = time;
	});

	return kCVReturnSuccess;
}

#pragma mark -
-(void)awakeFromNib
{
    [self enterFullScreenMode:[NSScreen mainScreen] withOptions:@{}];

//    hydra = [[SKRHydra alloc] init];
//    hydra.delegate = self;
    self.oculus = [[SKROculus alloc] init];

	[self setWantsLayer:YES];
	   
	SCNScene *scene = [SCNScene scene];
    self.scene = scene;

    _worldParentNode = [SCNNode node];
    [scene.rootNode addChildNode:_worldParentNode];
    
    playerNode = [SKRPlayer nodeWithHMDInfo:[self.oculus hmdInfo]];
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
    
    _creations = [NSMutableArray array];
    
	[self becomeFirstResponder];
	[self startWatchingJoysticks];
	
	[self setupLink];
}

-(void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	crosshairLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

#pragma mark - Input

-(BOOL)canBecomeKeyView
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [self handleMouseMovement:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self handleMouseMovement:theEvent];
}

- (void)handleMouseMovement:(NSEvent *)theEvent
{
    GLKQuaternion orientation = GLKQuaternionMakeWithAngleAndAxis(playerNode.rotation.w,
                                                                  playerNode.rotation.x,
                                                                  playerNode.rotation.y,
                                                                  playerNode.rotation.z);
    float sensitivity = 0.003;
    GLKQuaternion xMouseRotation = GLKQuaternionMakeWithAngleAndAxis(-theEvent.deltaX * sensitivity, 0, 1, 0);
    GLKQuaternion yMouseRotation = GLKQuaternionMakeWithAngleAndAxis(-theEvent.deltaY * sensitivity, 1, 0, 0);
    GLKQuaternion newOrientation = GLKQuaternionMultiply(GLKQuaternionMultiply(orientation, yMouseRotation), xMouseRotation);
    playerNode.rotation = SKRVector4FromQuaternion(newOrientation);
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _mouseButtonDown = YES;
    ALTPointCloudMeshCreation *newCreation = [[ALTPointCloudMeshCreation alloc] initWithParentNode:_scene.rootNode];
    [_creations addObject:newCreation];
    _currentCreation = newCreation;
    NSLog(@"Got a mouse down event: %ld", theEvent.buttonNumber);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    _mouseButtonDown = NO;
    NSLog(@"Got a mouse up event: %ld", (long)theEvent.buttonNumber);
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
    
    GLKVector3 newMovementDirection = _keyboardMovementDirection;
    
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
    else if (theEvent.keyCode == 49)
    {
        [self jump];
    }
    else if (theEvent.keyCode == 12)
    {
        _rollDirection += 1;
    }
    else if (theEvent.keyCode == 14)
    {
        _rollDirection -= 1;
    }
    
    _keyboardMovementDirection = newMovementDirection;
}

-(void)keyUp:(NSEvent *)theEvent
{
    GLKVector3 newMovementDirection = _keyboardMovementDirection;
    
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
    else if (theEvent.keyCode == 12)
    {
        _rollDirection -= 1;
    }
    else if (theEvent.keyCode == 14)
    {
        _rollDirection += 1;
    }
    
    _keyboardMovementDirection = newMovementDirection;
}

- (void)jump
{
    if (!playerNode.touchingGround)
    {
        return;
    }
    GLKVector3 gravity = [SKRPhysics sharedInstance].gravity;
    float jumpMagnitude = GLKVector3Length(gravity) * 1.5;
    GLKVector3 normalizedUpVector = GLKVector3Negate(GLKVector3Normalize(gravity));
    GLKVector3 jumpVelocity = GLKVector3MultiplyScalar(normalizedUpVector, jumpMagnitude);
    playerNode.velocity = GLKVector3Add(playerNode.velocity, jumpVelocity);
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
	}
	
//	[playerNode setMovement:movement];
	
}

#pragma mark - FPS Label

NSDate *nextFrameCounterReset;
NSUInteger frameCount;

- (void)renderer:(id<SCNSceneRenderer>)aRenderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
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
