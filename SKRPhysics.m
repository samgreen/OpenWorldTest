//
//  SKRPhysics.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/3/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRPhysics.h"
#import "SKREntity.h"
#import "SKRWorldGenerator.h"
#import "SKRMath.h"

SKRPhysics *sharedInstance;

@implementation SKRPhysics

+ (SKRPhysics *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SKRPhysics alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
//        _gravity = GLKVector3Make(0, -9.81, 0);
        _gravity = GLKVector3Make(0, -0.981, 0);
    }
    return self;
}

- (void)updateEntity:(SKREntity *)entity inWorld:(NSObject <SKRWorldGenerator>*)world deltaTime:(NSTimeInterval)deltaTime
{
    entity.acceleration = _gravity;
    entity.velocity = GLKVector3Add(entity.velocity, GLKVector3MultiplyScalar(entity.acceleration, deltaTime));
    GLKVector3 currentPosition = GLKVector3MakeWithSCNVector3(entity.position);
    GLKVector3 newPosition = GLKVector3Add(currentPosition, GLKVector3MultiplyScalar(entity.velocity, deltaTime));
    entity.position = SCNVector3MakeWithGLKVector3(newPosition);
}

@end
