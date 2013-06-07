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

+ (id)tree
{
    ALTTree *tree = [ALTTree node];
    
    SCNMaterial *branchMaterial = [SCNMaterial material];
    branchMaterial.diffuse.contents = [NSColor brownColor];

    SCNGeometry *trunkGeometry = [SCNTube tubeWithInnerRadius:0 outerRadius:0.5 height:5];
    trunkGeometry.materials = @[branchMaterial];

    SCNNode *trunkNode = [SCNNode nodeWithGeometry:trunkGeometry];
    [tree addChildNode:trunkNode];
    return tree;
}

@end
