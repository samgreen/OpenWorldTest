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
#import "ALTCylinders.h"
#import <GLKit/GLKit.h>

SCNMaterial *branchMaterial;

@interface ALTTransformStackNode : NSObject <NSCopying>

@property (nonatomic) float scale;
@property (nonatomic) GLKMatrix4 transform;

@end

@implementation ALTTransformStackNode

- (id)copyWithZone:(NSZone *)zone
{
    ALTTransformStackNode *newNode = [[ALTTransformStackNode alloc] init];
    newNode.transform = self.transform;
    newNode.scale = self.scale;
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
    });

    ALTTree *tree = (ALTTree *)[SCNNode node];

    ALTCylinders *cylinders = [[ALTCylinders alloc] init];
    ALTLSystem *lSystem = [[ALTLSystem alloc] initWithVariables:@[@"A", @"B"]
                                                      constants:@[@"+", @"-", @"*", @"/", @"[", @"]"]
                                                          rules:@{
                           @"A": @"AA",
                           @"B": @"A[+B][*B][/B]-B"
                           }];
    NSString *treeString = [lSystem process:@"B" numGenerations:6];
    
    ALTTransformStackNode *stackNode = [[ALTTransformStackNode alloc] init];
    stackNode.transform = GLKMatrix4Identity;
    stackNode.scale = 1.0;
    NSMutableArray *transformStack = [NSMutableArray arrayWithObject:stackNode];
    generateTreeNodesRecursive(treeString, 0, transformStack, cylinders);
    
    SCNGeometry *treeGeometry = [cylinders geometry];
    treeGeometry.materials = @[branchMaterial];
    tree.geometry = treeGeometry;
    
    return tree;
}

static void generateTreeNodesRecursive(NSString *treeString, int charIndex, NSMutableArray *transformStack, ALTCylinders *cylinders)
{
    if (charIndex >= [treeString length] || charIndex < 0)
    {
        return;
    }
    
    ALTTransformStackNode *oldStackNode = [transformStack lastObject];
    ALTTransformStackNode *newStackNode;

    GLKQuaternion plusRotation = GLKQuaternionMakeWithAngleAndAxis(M_PI / 4.0, 1, 0, 0);
    GLKQuaternion minusRotation = GLKQuaternionMakeWithAngleAndAxis(-M_PI / 4.0, 1, 0, 0);
    GLKQuaternion starRotation = GLKQuaternionMakeWithAngleAndAxis(M_PI / 4.0, 0, 0, 1);
    GLKQuaternion slashRotation = GLKQuaternionMakeWithAngleAndAxis(-M_PI / 4.0, 0, 0, 1);
    
    char symbol = [treeString characterAtIndex:charIndex];
    switch (symbol) {
        case 'A':
            newStackNode = addBranch(oldStackNode, cylinders);
            [transformStack removeLastObject];
            [transformStack addObject:newStackNode];
            break;
        case '+':
            newStackNode = rotate(oldStackNode, plusRotation);
            [transformStack removeLastObject];
            [transformStack addObject:newStackNode];
            break;
        case '-':
            newStackNode = rotate(oldStackNode, minusRotation);
            [transformStack removeLastObject];
            [transformStack addObject:newStackNode];
            break;
        case '*':
            newStackNode = rotate(oldStackNode, starRotation);
            [transformStack removeLastObject];
            [transformStack addObject:newStackNode];
            break;
        case '/':
            newStackNode = rotate(oldStackNode, slashRotation);
            [transformStack removeLastObject];
            [transformStack addObject:newStackNode];
            break;
        case '[':
            [transformStack addObject:[oldStackNode copy]];
            break;
        case ']':
            [transformStack removeLastObject];
            break;
        default:
            break;
    }
    generateTreeNodesRecursive(treeString, charIndex + 1, transformStack, cylinders);
}

static ALTTransformStackNode *addBranch(ALTTransformStackNode *stackNode, ALTCylinders *cylinders)
{
    [cylinders addCylinderWithTransform:GLKMatrix4Multiply(GLKMatrix4Multiply(stackNode.transform, GLKMatrix4MakeTranslation(0, trunkHeight / 2.0, 0)),
                                                           GLKMatrix4MakeScale(stackNode.scale, 1, stackNode.scale))];

    ALTTransformStackNode *newStackNode = [stackNode copy];
    newStackNode.scale = stackNode.scale * 0.97;
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(0, trunkHeight / 2.0, 0);
    newStackNode.transform = GLKMatrix4Multiply(stackNode.transform, translation);
    return newStackNode;
}

static ALTTransformStackNode *rotate(ALTTransformStackNode *stackNode, GLKQuaternion rotationQuat)
{
    ALTTransformStackNode *newStackNode = [stackNode copy];
    
    float offsetScale = M_PI / 2.0;
    float inverseScale = 1.0 - stackNode.scale;
    GLKQuaternion offset = GLKQuaternionMakeWithAngleAndAxis(-offsetScale / 2.0 + offsetScale * inverseScale * (arc4random() / (float)0x100000000),
                                                             offsetScale * inverseScale * (arc4random() / (float)0x100000000),
                                                             offsetScale * inverseScale * (arc4random() / (float)0x100000000),
                                                             offsetScale * inverseScale * (arc4random() / (float)0x100000000));
    GLKQuaternion offsetRotationQuat = GLKQuaternionMultiply(rotationQuat, offset);
    
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(offsetRotationQuat);
    
    newStackNode.transform = GLKMatrix4Multiply(stackNode.transform, rotation);
    return newStackNode;
}

@end
