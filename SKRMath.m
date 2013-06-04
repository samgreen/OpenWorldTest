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

GLKMatrix4 GLKMatrix4MakeWithCATransform3D(CATransform3D t)
{
    GLKMatrix4 matrix = GLKMatrix4Make(t.m11, t.m12, t.m13, t.m14,
                                       t.m21, t.m22, t.m21, t.m24,
                                       t.m31, t.m32, t.m33, t.m34,
                                       t.m41, t.m42, t.m43, t.m44);
    return matrix;
}