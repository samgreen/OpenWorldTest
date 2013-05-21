//
//  PlayerNode.m
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import "OWTPlayer.h"

@interface OWTPlayer ()
@property (nonatomic, assign) CGFloat rotationUpDown;
@property (nonatomic, assign) CGFloat rotationLeftRight;
@end

@interface OWTPlayer (Private)
- (void)buildPlayer;
@end

@implementation OWTPlayer
@synthesize movement;
@synthesize rotationUpDown;
@synthesize rotationLeftRight;

+ (OWTPlayer *)node {
	OWTPlayer * node = (OWTPlayer *)[super node];
	[node setMass:70];

    int hResolution = 1280;
    int vResolution = 800;
    float hScreenSizeMeters = 0.14976;
    float vScreenSizeMeters = 0.0935;
    float eyeToScreenDistanceMeters = 0.041;
    float halfScreenAspectRatio = hResolution / (2.0 * vResolution);
    float vFov = 2 * atan(vScreenSizeMeters / (2.0 * eyeToScreenDistanceMeters));
    float hFov = 2 * atan(halfScreenAspectRatio * tan(vFov / 2.0));
    float vFovDegrees = SKR_RADIANS_TO_DEGREES(vFov);
    float hFovDegrees = SKR_RADIANS_TO_DEGREES(hFov);
    
	{
        SCNCamera * camera = [SCNCamera camera];
        camera.zNear = 0.1;
        camera.zFar = 64;
        camera.xFov = hFovDegrees;
        camera.yFov = vFovDegrees;
        
        SCNNode *leftEye = [SCNNode node];
        leftEye.position = SCNVector3Make(-1.0, 0.0, 0.0);
        [leftEye setCamera:camera];
        node.leftEye = leftEye;
        
        [node addChildNode:leftEye];
    }
    {
        SCNCamera * camera = [SCNCamera camera];
        camera.zNear = 0.1;
        camera.zFar = 64;
        camera.xFov = hFovDegrees;
        camera.yFov = vFovDegrees;

        SCNNode *rightEye = [SCNNode node];
        rightEye.position = SCNVector3Make(1.0, 0.0, 0.0);
        [rightEye setCamera:camera];
        node.rightEye = rightEye;
        
        [node addChildNode:rightEye];
    }
	
	SCNLight * light = [SCNLight light];
	[light setType:SCNLightTypeOmni];
	[node setLight:light];
	
	[node buildPlayer];
	
	return node;
}

- (void)buildPlayer {
	[self setGeometry:[SCNBox boxWithWidth:1 height:1 length:1 chamferRadius:0]];
}

- (void)rotateByAmount:(CGSize)amount {
	
	rotationLeftRight += amount.width;
	if (rotationLeftRight > M_PI * 2) rotationLeftRight -= M_PI * 2;
	else if (rotationLeftRight < 0) rotationLeftRight += M_PI * 2;
	
	rotationUpDown += amount.height;
	if (rotationUpDown > M_PI * 2) rotationUpDown -= M_PI * 2;
	else if (rotationUpDown < 0) rotationUpDown += M_PI * 2;
	
	CATransform3D rotation = CATransform3DRotate(self.transform, amount.height, 1, 0, 0);
	[self setTransform:CATransform3DRotate(rotation, amount.width, 0, sinf(rotationUpDown), cosf(rotationUpDown))];
}

- (void)updatePositionWithRefreshPeriod:(CGFloat)refreshPeriod {
	[super updatePositionWithRefreshPeriod:refreshPeriod];
	
	SCNVector3 position = self.position;
	position.x -= sinf(rotationLeftRight) * (movement.x - movement.z) * refreshPeriod;
	position.y += cosf(rotationLeftRight) * (movement.x - movement.z) * refreshPeriod;
	
	position.x -= cosf(rotationLeftRight) * (movement.y - movement.w) * refreshPeriod;
	position.y -= sinf(rotationLeftRight) * (movement.y - movement.w) * refreshPeriod;
	[self setPosition:position];
}

@end