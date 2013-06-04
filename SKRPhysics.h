//
//  SKRPhysics.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/3/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

@class SKREntity;
@protocol SKRWorldGenerator;

@interface SKRPhysics : NSObject

@property (nonatomic) GLKVector3 gravity;

+ (SKRPhysics *)sharedInstance;
- (void)updateEntity:(SKREntity *)entity inWorld:(NSObject <SKRWorldGenerator>*)world deltaTime:(NSTimeInterval)deltaTime;

@end
