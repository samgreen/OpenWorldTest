//
//  ParticleNode.h
//  SceneKraft
//
//  Created by Tom Irving on 10/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMath.h>

@interface SKREntity : SCNNode

@property (nonatomic, assign) GLKVector3 velocity;
@property (nonatomic, assign) GLKVector3 acceleration;
@property (nonatomic, assign) CGFloat mass;
@property (nonatomic, readonly) BOOL touchingGround;

- (void)checkCollisionWithNodes:(NSArray *)nodes;

@end
