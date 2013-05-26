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

+ (OWTPlayer *)nodeWithHMDInfo:(OVR::HMDInfo)hmdInfo
{
	OWTPlayer * node = (OWTPlayer *)[super node];
	[node setMass:70];
    
    float halfScreenAspectRatio = (hmdInfo.HResolution * 0.5) / hmdInfo.VResolution;
    float halfScreenDistance = hmdInfo.VScreenSize * 0.5;
    float yFov = 2.0 * atanf(halfScreenDistance / hmdInfo.EyeToScreenDistance);
    float xFov = 2.0 * atanf(halfScreenAspectRatio * tanf(yFov / 2.0));
    float yFovDegrees = SKR_RADIANS_TO_DEGREES(yFov);
    float xFovDegrees = SKR_RADIANS_TO_DEGREES(xFov);    
    NSLog(@"yFov: %f, xFov: %f", yFovDegrees, xFovDegrees);
    
    xFovDegrees = 84.8;
    yFovDegrees = 97.55;
    
//    float halfIPD = hmdInfo.InterpupillaryDistance * 0.5f;
    node.interpupillaryDistance = hmdInfo.InterpupillaryDistance;
    
	{
        SCNCamera * camera = [SCNCamera camera];
        camera.zNear = 0.1;
        camera.zFar = 64;
        camera.xFov = xFovDegrees;
        camera.yFov = yFovDegrees;
        
        SCNNode *leftEye = [SCNNode node];
        leftEye.position = SCNVector3Make(-node.interpupillaryDistance * 0.5, 0.0, 0.0);
        [leftEye setCamera:camera];
        node.leftEye = leftEye;

        [node addChildNode:leftEye];
    }
    {
        SCNCamera * camera = [SCNCamera camera];
        camera.zNear = 0.1;
        camera.zFar = 64;
        camera.xFov = xFovDegrees;
        camera.yFov = yFovDegrees;

        SCNNode *rightEye = [SCNNode node];
        rightEye.position = SCNVector3Make(node.interpupillaryDistance * 0.5, 0.0, 0.0);
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

- (void)setInterpupillaryDistance:(float)interpupillaryDistance
{
    _interpupillaryDistance = interpupillaryDistance;
    self.leftEye.position = SCNVector3Make(-self.interpupillaryDistance * 0.5, 0.0, 0.0);
    self.rightEye.position = SCNVector3Make(self.interpupillaryDistance * 0.5, 0.0, 0.0);
}

- (void)buildPlayer {
	[self setGeometry:[SCNBox boxWithWidth:1 height:1 length:1 chamferRadius:0]];
}

@end