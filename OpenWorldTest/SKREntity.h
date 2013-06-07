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

@property (nonatomic) GLKVector3 velocity;
@property (nonatomic) GLKVector3 acceleration;
@property (nonatomic) CGFloat mass;
@property (nonatomic) BOOL touchingGround;

- (void)checkCollisionWithNodes:(NSArray *)nodes;

@end
