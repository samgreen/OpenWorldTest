//
//  ALTCylinders.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/9/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

@interface ALTCylinders : NSObject

@property (nonatomic, strong) SCNGeometry *geometry;

- (void)addCylinderWithTransform:(GLKMatrix4)transform;

@end
