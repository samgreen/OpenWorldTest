//
//  PlayerNode.m
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import "OWTPlayer.h"
#import "SKRMath.h"
@interface OWTPlayer ()
@end

@interface OWTPlayer (Private)
- (void)buildPlayer;
@end

@implementation OWTPlayer

+ (OWTPlayer *)node {
	OWTPlayer * node = (OWTPlayer *)[super node];
	[node setMass:70];
	
	SCNLight *light = [SCNLight light];
	[light setType:SCNLightTypeOmni];
	[node setLight:light];
	
    [node createCameras];
	[node buildPlayer];
    [node createArms];
	
	return node;
}

- (void)createCameras {
    int hResolution = 1280;
    int vResolution = 800;
    __unused float hScreenSizeMeters = 0.14976;
    float vScreenSizeMeters = 0.0935;
    float eyeToScreenDistanceMeters = 0.041;
    float halfScreenAspectRatio = hResolution / (2.0 * vResolution);
    float vFov = 2 * atan(vScreenSizeMeters / (2.0 * eyeToScreenDistanceMeters));
    float hFov = 2 * atan(halfScreenAspectRatio * tan(vFov / 2.0));
    float vFovDegrees = SKR_RADIANS_TO_DEGREES(vFov);
    float hFovDegrees = SKR_RADIANS_TO_DEGREES(hFov);
    
    for (NSUInteger i = 0; i < 2; i++) {
        SCNCamera *camera = [SCNCamera camera];
        camera.zNear = 0.1;
        camera.zFar = 64;
        camera.xFov = hFovDegrees;
        camera.yFov = vFovDegrees;
        
        SCNNode *eyeNode = [SCNNode node];
        [eyeNode setCamera:camera];
        
        [self addChildNode:eyeNode];
        if (i == 0) {
            eyeNode.position = SCNVector3Make(-0.05, 0.0, 0.0);
            self.leftEye = eyeNode;
        } else if (i == 1) {
            eyeNode.position = SCNVector3Make(0.05, 0.0, 0.0);
            self.rightEye = eyeNode;
        }
    }
}

- (void)buildPlayer {
	[self setGeometry:[SCNBox boxWithWidth:1 height:1 length:1 chamferRadius:0]];
}

- (void)createArms {
    SCNCapsule *capsule = [SCNCapsule capsuleWithCapRadius:0.2 height:1];
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents = [NSColor blackColor];
    capsule.materials = @[material];
    for (NSUInteger i = 0; i < 2; i++) {
        
        SCNNode *handCenterNode = [SCNNode node];
        [self addChildNode:handCenterNode];
        
        SCNNode *handNode = [SCNNode nodeWithGeometry:capsule];
        [handCenterNode addChildNode:handNode];
        
        CGFloat x = 0.5;
        CGFloat y = 0;
        CGFloat z = -2; // negative=forwards from eyes
        if (i == 0) {
            handCenterNode.position = SCNVector3Make(-x, y, z);
            self.leftHand = handNode;
        } else if (i == 1) {
            handCenterNode.position = SCNVector3Make(x, y, z);
            self.rightHand = handNode;
        }
    }
}

- (void)updateArm:(SKRRightLeft)rightLeft
         position:(SCNVector3)position
      orientation:(SCNVector4)orientation {
    SCNNode *hand;
    if (rightLeft == SKRLeft) {
        hand = self.leftHand;
    } else if (rightLeft == SKRRight) {
        hand = self.rightHand;
    }
    hand.position = position;
    hand.rotation = orientation;
}

@end