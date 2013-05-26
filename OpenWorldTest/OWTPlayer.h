//
//  PlayerNode.h
//  SceneKraft
//
//  Created by Tom Irving on 09/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "OWTEntity.h"

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

+ (OWTPlayer *)node;

- (void)updateArm:(SKRRightLeft)rightLeft
         position:(SCNVector3)position
      orientation:(SCNVector4)orientation;

@end