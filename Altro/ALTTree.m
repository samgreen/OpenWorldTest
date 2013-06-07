//
//  ALTTree.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTTree.h"
#import <SceneKit/SceneKit.h>

@implementation ALTTree

+ (ALTTree *)tree
{
    ALTTree *tree = (ALTTree *)[super node];
    
    SCNMaterial *branchMaterial = [SCNMaterial material];
    branchMaterial.diffuse.contents = [NSColor brownColor];

    float height = 5.0;
    SCNGeometry *trunkGeometry = [SCNCylinder cylinderWithRadius:0.5 height:height];
    trunkGeometry.materials = @[branchMaterial];

    SCNNode *trunkNode = [SCNNode nodeWithGeometry:trunkGeometry];
    trunkNode.pivot = CATransform3DMakeTranslation(0, -height * 0.4, 0);
    [tree addChildNode:trunkNode];
    return tree;
}

@end
