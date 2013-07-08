//
//  ALTPointCloudMeshCreation.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 7/7/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

@class SCNNode;

@interface ALTPointCloudMeshCreation : NSObject

- (id)initWithParentNode:(SCNNode *)parentNode;
- (void)addSphereAtPoint:(GLKVector3)point radius:(float)radius numPoints:(int)numPoints;

@end
