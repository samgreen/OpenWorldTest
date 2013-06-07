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
        _gravity = GLKVector3Make(0, -9.81, 0);
        _friction = GLKVector3Make(0.05, 0.0, 0.05);
    }
    return self;
}

- (void)updateEntity:(SKREntity *)entity inWorld:(NSObject <SKRWorldGenerator>*)world deltaTime:(NSTimeInterval)deltaTime
{
    entity.acceleration = _gravity;
    entity.velocity = GLKVector3Add(entity.velocity, GLKVector3MultiplyScalar(entity.acceleration, deltaTime));
    GLKVector3 inverseFriction = GLKVector3Subtract(GLKVector3Make(1, 1, 1), GLKVector3MultiplyScalar(self.friction, deltaTime));
    entity.velocity = GLKVector3Multiply(entity.velocity, inverseFriction);
    GLKVector3 currentPosition = GLKVector3MakeWithSCNVector3(entity.position);
    GLKVector3 newPosition = GLKVector3Add(currentPosition, GLKVector3MultiplyScalar(entity.velocity, deltaTime));
 
    float terrainHeight = [world terrainHeightAt:newPosition];
    GLKVector3 normalizedUpVector = GLKVector3Normalize(GLKVector3Negate(self.gravity));
    float positionAlongUpVector = GLKVector3DotProduct(newPosition, normalizedUpVector);
    float entityHeight = 1.75;
    if (positionAlongUpVector < terrainHeight + entityHeight)
    {
        float velocityAlongUpVector = GLKVector3DotProduct(entity.velocity, normalizedUpVector);
        
        GLKVector3 correctedVelocity = GLKVector3Subtract(entity.velocity, GLKVector3MultiplyScalar(normalizedUpVector, velocityAlongUpVector));
        entity.velocity = correctedVelocity;
        float amountPastTerrainHeight = terrainHeight - positionAlongUpVector;
        
        newPosition = GLKVector3Add(newPosition, GLKVector3MultiplyScalar(normalizedUpVector, amountPastTerrainHeight + 1.75));
    }

    if (positionAlongUpVector < terrainHeight + entityHeight * 1.5)  // buffer
    {
        entity.touchingGround = YES;
    }
    else
    {
        entity.touchingGround = NO;
    }
    
    entity.position = SCNVector3MakeWithGLKVector3(newPosition);
}

@end
