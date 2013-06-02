//
//  ALTWorldGenerator.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTWorldGenerator.h"
#import "SKRMath.h"
#import <GLKit/GLKMath.h>
#import <SceneKit/SceneKit.h>

@implementation ALTWorldGenerator
{
    SCNNode *worldNode;
}

- (SCNVector3)initialPlayerPosition
{
    return SCNVector3Make(0, 0, 0);
}

- (SCNVector4)initialPlayerRotation
{
    GLKQuaternion q = GLKQuaternionMakeWithAngleAndAxis(0, 1, 0, 0);
    return SKRVector4FromQuaternion(q);
}

- (SCNNode *)worldNodeForPlayerPosition:(SCNVector3)newPlayerPosition rotation:(SCNVector4)newPlayerRotation
{
    return worldNode;
}

- (id)init
{
    self = [super init];
    if (self) {
        worldNode = [SCNNode node];
        
        SCNGeometry *sphereGeometry = [SCNSphere sphereWithRadius:0.3];
        SCNMaterial *material = [SCNMaterial material];
        material.diffuse.contents = [NSColor orangeColor];
        sphereGeometry.materials = @[material];
        
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphereGeometry];
        sphereNode.position = SCNVector3Make(0, 0, -1);
        [worldNode addChildNode:sphereNode];
    }
    return self;
}

@end
