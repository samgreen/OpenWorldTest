//
//  ALTHeightField.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/2/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMath.h>

@interface ALTHeightField : NSObject

@property (nonatomic) float width;
@property (nonatomic) float length;
@property (nonatomic, strong) SCNGeometry *geometry;

- (id)initWithRows:(int)r columns:(int)c heights:(float *)h xspace:(float)xs zspace:(float)zs;
- (float)heightAt:(GLKVector3)location;

@end
