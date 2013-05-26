//
//  PlayerNode.h
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMath.h>
#import "OWTEntity.h"
#import "OVR_Device.h"

@interface OWTPlayer : OWTEntity {
}

@property (nonatomic, retain) SCNNode *leftEye;
@property (nonatomic, retain) SCNNode *rightEye;
@property (nonatomic) GLKVector3 movementDirection;
@property (nonatomic) float interpupillaryDistance;

+ (OWTPlayer *)nodeWithHMDInfo:(OVR::HMDInfo)hmdInfo;

@end