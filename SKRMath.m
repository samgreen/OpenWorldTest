//
//  SKRMath.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/3/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "SKRMath.h"

SCNVector4 SKRVector4FromQuaternion(GLKQuaternion q)
{
    return SKRVector4FromQuaternionValues(q.x, q.y, q.z, q.w);
}

SCNVector4 SKRVector4FromQuaternionValues(float x, float y, float z, float w) {
    GLKQuaternion rotation = GLKQuaternionMake(x, y, z, w);
    GLKVector3 axis = GLKQuaternionAxis(rotation);
    float angle = GLKQuaternionAngle(rotation);
    
    return SCNVector4Make(axis.x, axis.y, axis.z, angle);
}

GLKVector3 GLKVector3MakeWithSCNVector3(SCNVector3 v)
{
    return GLKVector3Make(v.x, v.y, v.z);
}

SCNVector3 SCNVector3MakeWithGLKVector3(GLKVector3 v)
{
    return SCNVector3Make(v.x, v.y, v.z);
}
