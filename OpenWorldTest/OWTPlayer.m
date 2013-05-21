//
//  PlayerNode.m
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import "OWTPlayer.h"

@interface OWTPlayer ()
@end

@interface OWTPlayer (Private)
- (void)buildPlayer;
@end

@implementation OWTPlayer

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

@end