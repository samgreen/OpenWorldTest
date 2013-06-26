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

@property (nonatomic) GLKMatrix4 transform;

@end

@implementation ALTTransformStackNode

- (id)copyWithZone:(NSZone *)zone
{
    ALTTransformStackNode *newNode = [[ALTTransformStackNode alloc] init];
    newNode.transform = self.transform;
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
                                                      constants:@[@"+", @"-", @"[", @"]"]
                                                          rules:@{
                           @"A": @"AA",
                           @"B": @"A[+B]-B"
                           }];
    NSString *treeString = [lSystem process:@"B" numGenerations:6];
    
    ALTTransformStackNode *stackNode = [[ALTTransformStackNode alloc] init];
    stackNode.transform = GLKMatrix4Identity;
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
    
    ALTTransformStackNode *stackNode = [transformStack lastObject];
    GLKMatrix4 transform = stackNode.transform;
    GLKMatrix4 newTransform = transform;
    
    char symbol = [treeString characterAtIndex:charIndex];
    switch (symbol) {
        case 'A':
            addBranch(transform, &newTransform, cylinders);
            stackNode.transform = newTransform;
            break;
        case '+':
            rotate(M_PI / 4.0, transform, &newTransform);
            stackNode.transform = newTransform;
            break;
        case '-':
            rotate(-M_PI / 4.0, transform, &newTransform);
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
    generateTreeNodesRecursive(treeString, charIndex + 1, transformStack, cylinders);
}

static void addBranch(GLKMatrix4 transform, GLKMatrix4 *outNewTransform, ALTCylinders *cylinders)
{
    [cylinders addCylinderWithTransform:transform];
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(0, trunkHeight / 2.0, 0);
//    GLKMatrix4 scale = GLKMatrix4MakeScale(1.0, 1.1, 1.0);
//    *outNewTransform = CATransform3DConcat(CATransform3DConcat(scale, translation), transform);
    *outNewTransform = GLKMatrix4Multiply(transform, translation);
}

static void rotate(float angle, GLKMatrix4 transform, GLKMatrix4 *outNewTransform)
{
    GLKMatrix4 rotation = GLKMatrix4MakeRotation(angle, 1, 0, 0);
    *outNewTransform = GLKMatrix4Multiply(transform, rotation);
}

@end
