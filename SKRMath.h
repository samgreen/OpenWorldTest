//
//  SKRMath.h
//  OpenWorldTest
//
//  Created by Luke Iannini on 5/26/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

#ifdef __cplusplus
extern "C" {
#endif

SCNVector4 SKRVector4FromQuaternionValues(float x, float y, float z, float w);
SCNVector4 SKRVector4FromQuaternion(GLKQuaternion);
GLKVector3 GLKVector3MakeWithSCNVector3(SCNVector3 v);
SCNVector3 SCNVector3MakeWithGLKVector3(GLKVector3 v);

typedef NS_ENUM(NSUInteger, SKRSide){
    SKRLeft,
    SKRRight
};

#ifdef __cplusplus
}
#endif