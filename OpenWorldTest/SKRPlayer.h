//
//  PlayerNode.h
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMath.h>
#import "SKREntity.h"
#import "OVR_Device.h"
#import "SKRMath.h"

@interface SKRPlayer : SKREntity {
}

@property (nonatomic, strong) SCNNode *leftEye;
@property (nonatomic, strong) SCNNode *rightEye;

@property (nonatomic, strong) SCNNode *leftHand;
@property (nonatomic, strong) SCNNode *rightHand;

@property (nonatomic) GLKVector3 movementDirection;
@property (nonatomic) float interpupillaryDistance;

+ (SKRPlayer *)nodeWithHMDInfo:(OVR::HMDInfo)hmdInfo;

- (void)updateArm:(SKRSide)side
         position:(SCNVector3)position
      rotation:(SCNVector4)rotation;

@end