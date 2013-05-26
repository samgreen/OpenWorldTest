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

typedef NS_ENUM(NSUInteger, SKRRightLeft){
    SKRLeft,
    SKRRight
};

@interface OWTPlayer : OWTEntity {
}

@property (nonatomic, strong) SCNNode *leftEye;
@property (nonatomic, strong) SCNNode *rightEye;

@property (nonatomic, strong) SCNNode *leftHand;
@property (nonatomic, strong) SCNNode *rightHand;

@property (nonatomic) GLKVector3 movementDirection;
@property (nonatomic) float interpupillaryDistance;

+ (OWTPlayer *)nodeWithHMDInfo:(OVR::HMDInfo)hmdInfo;

- (void)updateArm:(SKRRightLeft)rightLeft
         position:(SCNVector3)position
      orientation:(SCNVector4)orientation;

@end