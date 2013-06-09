//
//  ALTCylinders.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/9/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTCylinders.h"
#import <GLKit/GLKMath.h>
#import "SKRMath.h"

@implementation ALTCylinders
{
    SCNCylinder *_cylinder;
    
    SCNGeometryElement *_elements;
    SCNGeometrySource *_vertexSource;
    SCNGeometrySource *_normalSource;
    SCNGeometrySource *_texCoordSource;
    
    int *_indexData;
    int _indexDataSize;
    int _numIndices;
    
    SCNVector3 *_vertexData;
    int _vertexDataSize;
    int _numVertices;
    
    SCNVector3 *_normalData;
    int _normalDataSize;
    int _numNormals;
    
    CGPoint *_texCoordData;
    int _texCoordDataSize;
    int _numTexCoords;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cylinder = [SCNCylinder cylinderWithRadius:1.0 height:5.0];
//        _cylinder.radialSegmentCount = 8;
        
        _indexDataSize = 100 * sizeof(int);
        _indexData = (int *)malloc(_indexDataSize);
        
        _vertexDataSize = 100 * sizeof(SCNVector3);
        _vertexData = (SCNVector3 *)malloc(_vertexDataSize);

        _normalDataSize = 100 * sizeof(SCNVector3);
        _normalData = (SCNVector3 *)malloc(_normalDataSize);

        _texCoordDataSize = 100 * sizeof(CGPoint);
        _texCoordData = (CGPoint *)malloc(_texCoordDataSize);
    }
    return self;
}

- (void)dealloc
{
    [self freePointers];
}

- (void)freePointers
{
    if (_indexData != NULL)
    {
        free(_indexData);
        _indexData = NULL;
    }
    if (_vertexData != NULL)
    {
        free(_vertexData);
        _vertexData = NULL;
    }
    if (_normalData != NULL)
    {
        free(_normalData);
        _normalData = NULL;
    }
    if (_texCoordData != NULL)
    {
        free(_texCoordData);
        _texCoordData = NULL;
    }
}

- (void)addCylinderWithTransform:(GLKMatrix4)transform
{
    for (int i = 0; i < _cylinder.geometryElementCount; i++)
    {
        SCNGeometryElement *geometryElement = [_cylinder geometryElementAtIndex:i];
        assert(geometryElement.primitiveType == SCNGeometryPrimitiveTypeTriangles && geometryElement.bytesPerIndex == 2);
        // We know that SCNCylinder uses shorts for its indices
        short *elementData = (short *)[geometryElement.data bytes];
        // We know that SCNCylinders use GL_TRIANGLES, so there are 3 indices per primitive
        for (int i = 0; i < geometryElement.primitiveCount * 3; i++)
        {
            int newIndex = elementData[i] + _numVertices;
            addInt(newIndex, &_indexData, &_indexDataSize, &_numIndices);
        }
    }

    NSArray *vertexSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    assert([vertexSources count] == 1);
    for (SCNGeometrySource *source in vertexSources) {
        assert(source.bytesPerComponent == 4);
        // We use GLKVector3 here for two reasons: 1) It's got floats intead of doubles (which SCNVector3 has), so it fits the data, and 2) it's easier to transform
        GLKVector3 *sourceData = (GLKVector3 *)[source.data bytes];
        for (int i = 0; i < source.vectorCount; i++)
        {
            GLKVector3 vertex = sourceData[i];
            GLKVector4 translatableVertex = GLKVector4MakeWithVector3(vertex, 1.0);
            GLKVector4 transformedVertex = GLKMatrix4MultiplyVector4(transform, translatableVertex);
            addVector(GLKVector3MakeWithArray(transformedVertex.v), &_vertexData, &_vertexDataSize, &_numVertices);
        }
    }
    
    bool isInvertible;
    GLKMatrix4 normalTransform = GLKMatrix4Transpose(GLKMatrix4Invert(transform, &isInvertible));
    NSAssert(isInvertible, @"Transform was not invertible!");
    NSArray *normalSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticNormal];
    assert([normalSources count] == 1);
    for (SCNGeometrySource *source in normalSources) {
        // We use GLKVector3 here for two reasons: 1) It's got floats intead of doubles (which SCNVector3 has), so it fits the data, and 2) it's easier to transform
        GLKVector3 *sourceData = (GLKVector3 *)[source.data bytes];
        for (int i = 0; i < source.vectorCount; i++)
        {
            GLKVector3 normal = sourceData[i];
            GLKVector3 transformedNormal = GLKMatrix4MultiplyVector3(normalTransform, normal);
            addVector(transformedNormal, &_normalData, &_normalDataSize, &_numNormals);
        }
    }

    NSArray *texCoordSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticTexcoord];
    assert([texCoordSources count] == 1);
    for (SCNGeometrySource *source in texCoordSources) {
        CGPoint *sourceData = (CGPoint *)[source.data bytes];
        for (int i = 0; i < source.vectorCount; i++)
        {
            CGPoint texCoord = sourceData[i];
            addPoint(texCoord, &_texCoordData, &_texCoordDataSize, &_numTexCoords);
        }
    }
    
//    NSLog(@"There are %d vertices, %d normals, and %d texCoords", _numVertices, _numNormals, _numTexCoords);
}

static void addVector(GLKVector3 vector, SCNVector3 **data, int *inOutDataSize, int *inOutNumVectors)
{
    if (*inOutNumVectors * sizeof(SCNVector3) >= *inOutDataSize)
    {
        SCNVector3 *largerData = (SCNVector3 *)realloc(*data, *inOutDataSize * 2);
        assert(largerData != NULL);
        *data = largerData;
        *inOutDataSize = *inOutDataSize * 2;
    }
    (*data)[*inOutNumVectors] = SCNVector3Make(vector.x, vector.y, vector.z);
    *inOutNumVectors = *inOutNumVectors + 1;
}

static void addPoint(CGPoint point, CGPoint **data, int *inOutDataSize, int *inOutNumVectors)
{
    if (*inOutNumVectors * sizeof(CGPoint) >= *inOutDataSize)
    {
        CGPoint *largerData = (CGPoint *)realloc(*data, *inOutDataSize * 2);
        assert(largerData != NULL);
        *data = largerData;
        *inOutDataSize = *inOutDataSize * 2;
    }
    (*data)[*inOutNumVectors] = point;
    *inOutNumVectors = *inOutNumVectors + 1;
}

static void addInt(int value, int **data, int *inOutDataSize, int *inOutNumValues)
{
    if (*inOutNumValues * sizeof(int) >= *inOutDataSize)
    {
        int *largerData = (int *)realloc(*data, *inOutDataSize * 2);
        assert(largerData != NULL);
        *data = largerData;
        *inOutDataSize = *inOutDataSize * 2;
    }
    (*data)[*inOutNumValues] = value;
    *inOutNumValues = *inOutNumValues + 1;
}

- (SCNGeometry *)geometry
{
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:_indexData length:_indexDataSize] primitiveType:SCNGeometryPrimitiveTypeTriangles primitiveCount:_numIndices bytesPerIndex:4];
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:_vertexData count:_numVertices];
    SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithNormals:_normalData count:_numNormals];
    SCNGeometrySource *texCoordSource = [SCNGeometrySource geometrySourceWithTextureCoordinates:_texCoordData count:_numTexCoords];
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource, texCoordSource] elements:@[element]];
    
    [self freePointers];
    
    return geometry;
}

@end
