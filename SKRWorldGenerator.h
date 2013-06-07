//
//  SKRWorldGenerator.h
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/1/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKMath.h>

@protocol SKRWorldGenerator <NSObject>

- (SCNVector3)initialPlayerPosition;
- (SCNVector4)initialPlayerRotation;
- (SCNNode *)worldNodeForPlayerPosition:(SCNVector3)newPlayerPosition rotation:(SCNVector4)newPlayerRotation;
- (float)terrainHeightAt:(GLKVector3)location;
- (BOOL)playerShouldHaveLight;

@end
