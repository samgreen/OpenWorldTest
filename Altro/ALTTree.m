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
SCNTube *branchGeometry;

@interface ALTTransformStackNode : NSObject <NSCopying>

@property (nonatomic) CATransform3D transform;
@property (nonatomic, strong) SCNNode *parent;

@end

@implementation ALTTransformStackNode

- (id)copyWithZone:(NSZone *)zone
{
    ALTTransformStackNode *newNode = [[ALTTransformStackNode alloc] init];
    newNode.transform = self.transform;
    newNode.parent = self.parent;
    return newNode;
}

@end

static float trunkHeight = 1.0;

@implementation ALTTree

+ (ALTTree *)tree
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branchMaterial = [SCNMaterial material];
        branchMaterial.diffuse.contents = [NSColor brownColor];
        
        branchGeometry = [SCNCylinder cylinderWithRadius:1.0 height:trunkHeight];
        branchGeometry.radialSegmentCount = 8;
        branchGeometry.materials = @[branchMaterial];
    });

    ALTLSystem *lSystem = [[ALTLSystem alloc] initWithVariables:@[@"A", @"B"]
                                                      constants:@[@"+", @"-", @"[", @"]"]
                                                          rules:@{
                           @"A": @"AA",
                           @"B": @"A[+B]-B"
                           }];
    NSString *treeString = [lSystem process:@"B" numGenerations:6];
    
    ALTTree *treeParent = (ALTTree *)[SCNNode node];
    ALTTransformStackNode *node = [[ALTTransformStackNode alloc] init];
    node.parent = treeParent;
    node.transform = CATransform3DIdentity;
    NSMutableArray *transformStack = [NSMutableArray arrayWithObject:node];
    generateTreeNodesRecursive(treeString, 0, transformStack);
    
    return treeParent;
}

static void generateTreeNodesRecursive(NSString *treeString, int charIndex, NSMutableArray *transformStack)
{
    if (charIndex >= [treeString length] || charIndex < 0)
    {
        return;
    }
    
    ALTTransformStackNode *stackNode = [transformStack lastObject];
    SCNNode *parent = stackNode.parent;
    CATransform3D transform = stackNode.transform;
    SCNNode *newParent = parent;
    CATransform3D newTransform = transform;
    
    char symbol = [treeString characterAtIndex:charIndex];
    switch (symbol) {
        case 'A':
            addBranch(parent, transform, &newParent, &newTransform);
            stackNode.parent = newParent;
            stackNode.transform = newTransform;
            break;
        case '+':
            rotate(M_PI / 4.0, transform, &newTransform);
            stackNode.parent = newParent;
            stackNode.transform = newTransform;
            break;
        case '-':
            rotate(-M_PI / 4.0, transform, &newTransform);
            stackNode.parent = newParent;
            stackNode.transform = newTransform;
            break;
        case '[':
            [transformStack addObject:[stackNode copy]];
            break;
        case ']':
            [transformStack removeLastObject];
            break;
        default:
            break;
    }
    generateTreeNodesRecursive(treeString, charIndex + 1, transformStack);
}

static void addBranch(SCNNode *parent, CATransform3D transform, SCNNode **outNewParent, CATransform3D *outNewTransform)
{
    SCNNode *branchNode = [SCNNode nodeWithGeometry:branchGeometry];
    branchNode.pivot = CATransform3DMakeTranslation(0, -trunkHeight / 2.0, 0);
    branchNode.transform = transform;
    [parent addChildNode:branchNode];
    *outNewParent = branchNode;
    CATransform3D translation = CATransform3DMakeTranslation(0, trunkHeight / 2.0, 0);
    CATransform3D scale = CATransform3DMakeScale(1.0, 1.0, 1.0);
    *outNewTransform = CATransform3DConcat(scale, translation);
}

static void rotate(float angle, CATransform3D transform, CATransform3D *outNewTransform)
{
    CATransform3D rotation = CATransform3DMakeRotation(angle, 1, 0, 0);
    *outNewTransform = CATransform3DConcat(rotation, transform);
}

@end
