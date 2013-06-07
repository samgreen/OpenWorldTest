//
//  ParticleNode.m
//  SceneKraft
//
//  Created by Tom Irving on 10/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import "SKREntity.h"

@implementation SKREntity

// Standard units.
CGFloat const kGravityAcceleration = -9.81;
CGFloat const kJumpHeight = 1.5;
CGFloat const kPlayerMovementSpeed = 1.4;

- (void)checkCollisionWithNodes:(NSArray *)nodes {
	// TODO: Make this better.
	
	self.touchingGround = NO;
	__block SCNVector3 selfPosition = self.position;
	
	[nodes enumerateObjectsUsingBlock:^(SCNNode * node, NSUInteger idx, BOOL *stop) {
		
		if (self != node)
		{
			if (NodeCollision(node,selfPosition))
			{
				selfPosition.y = node.position.z+1.5;
				self.velocity = GLKVector3Multiply(self.velocity, GLKVector3Make(1, 0, 1));
				node.opacity = 0.5;
				
				self.touchingGround = YES;
				*stop = YES;
			}
		}
	}];
	
	[self setPosition:selfPosition];
}

BOOL NodeCollision(SCNNode *node, SCNVector3 point)
{
	SCNVector3 min, max;
	
	[node getBoundingBoxMin:&min max:&max];
	
	min.x += node.position.x;
	min.y += node.position.y;
	min.z += node.position.z;
	
	max.x += node.position.x;
	max.y += node.position.y;
	max.z += node.position.z;
	
	return point.x <= max.x && point.x >= min.x &&
	point.y <= max.y && point.y >= min.y &&
	point.z <= max.z && point.z >= min.z ;
}

@end