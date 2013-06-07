//
//  ALTTree.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTTree.h"
#import <SceneKit/SceneKit.h>

SCNMaterial *branchMaterial;
SCNGeometry *branchGeometry;

@implementation ALTTree

+ (ALTTree *)tree
{
    ALTTree *tree = (ALTTree *)[super node];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branchMaterial = [SCNMaterial material];
        branchMaterial.diffuse.contents = [NSColor brownColor];
        
        branchGeometry = [SCNCylinder cylinderWithRadius:1.0 height:1.0];
        branchGeometry.materials = @[branchMaterial];
    });

    SCNNode *trunkNode = [SCNNode nodeWithGeometry:branchGeometry];
    float height = 50;
    trunkNode.pivot = CATransform3DMakeTranslation(0, -0.4, 0);
    trunkNode.transform = CATransform3DMakeScale(1, height, 1);
    [tree addChildNode:trunkNode];
    return tree;
}

@end
