//
//  ALTTree.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTTree.h"
#import <SceneKit/SceneKit.h>
#import "ALTLSystem.h"

SCNMaterial *branchMaterial;
SCNGeometry *branchGeometry;

@implementation ALTTree

static float trunkHeight = 5.0;

+ (ALTTree *)tree
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branchMaterial = [SCNMaterial material];
        branchMaterial.diffuse.contents = [NSColor brownColor];
        
        branchGeometry = [SCNCylinder cylinderWithRadius:1.0 height:trunkHeight];
        branchGeometry.materials = @[branchMaterial];
    });

    ALTLSystem *lSystem = [[ALTLSystem alloc] initWithVariables:@[@"A"] constants:@[@"+"] rules:@{@"A": @"A+A"}];
    NSString *treeString = [lSystem process:@"A" numGenerations:5];
    
    ALTTree *treeParent = (ALTTree *)[SCNNode node];
    generateTreeNodesRecursive(treeString, treeParent, 0, CATransform3DIdentity);
    
    return treeParent;
}

static void generateTreeNodesRecursive(NSString *treeString, SCNNode *parent, int charIndex, CATransform3D transform)
{
    if (charIndex >= [treeString length] || charIndex < 0)
    {
        return;
    }
    
    SCNNode *newParent = parent;
    CATransform3D newTransform = transform;
    
    char symbol = [treeString characterAtIndex:charIndex];
    switch (symbol) {
        case 'A':
            addBranch(parent, transform, &newParent, &newTransform);
            break;
        case '+':
            rotate(transform, &newTransform);
        default:
            break;
    }
    generateTreeNodesRecursive(treeString, newParent, charIndex + 1, newTransform);
}

static void addBranch(SCNNode *parent, CATransform3D transform, SCNNode **outNewParent, CATransform3D *outNewTransform)
{
    SCNNode *branchNode = [SCNNode nodeWithGeometry:branchGeometry];
    branchNode.pivot = CATransform3DMakeTranslation(0, -0.4, 0);
    branchNode.transform = transform;
    [parent addChildNode:branchNode];
    *outNewParent = branchNode;
    CATransform3D translation = CATransform3DMakeTranslation(0, trunkHeight * 0.9, 0);
    CATransform3D scale = CATransform3DMakeScale(0.8, 0.8, 0.8);
    *outNewTransform = CATransform3DConcat(translation, scale);
}

static void rotate(CATransform3D transform, CATransform3D *outNewTransform)
{
    CATransform3D rotation = CATransform3DMakeRotation(M_PI / 18.0, 1, 0, 0);
    *outNewTransform = CATransform3DConcat(rotation, transform);
}

@end
