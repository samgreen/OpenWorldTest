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
//    SCNCylinder *_cylinder;
    
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

//SCNCapsule *cylinder;
//SCNCylinder *cylinder;

int *cylinderIndices = NULL;
GLKVector3 *cylinderVertices = NULL;
GLKVector3 *cylinderNormals = NULL;
GLKVector2 *cylinderTexCoords = NULL;
int numCylinderVertices = 0;
int numCylinderIndices = 0;
int numCylinderTriangles = 0;

static void createCylinderVertices(int numSegments, float width, float height)
{
    assert(cylinderVertices == NULL && cylinderNormals == NULL && cylinderTexCoords == NULL);
    // 2 vertices per segment per ring, so that we can have normals facing outwards for the side triangles and up/downwards for the top/bottom triangles
    // plus 2 more vertices, one at the bottom center and one at the top center
    cylinderVertices = (GLKVector3 *)malloc((numSegments * 2 * 2 + 2) * sizeof(GLKVector3));
    cylinderNormals = (GLKVector3 *)malloc((numSegments * 2 * 2 + 2) * sizeof(GLKVector3));
    cylinderTexCoords = (GLKVector2 *)malloc((numSegments * 2 * 2 + 2) * sizeof(GLKVector2));

    float angle = 0;
    float angleIncrement = (M_PI * 2) / numSegments;
    float percent = 0;
    float percentIncrement = 1.0 / numSegments;
    float radius = width / 2.0;
    float halfHeight = height / 2.0;
    for (int i = 0; i < numSegments; i++)
    {
        float x = radius * cosf(angle);
        float z = radius * sinf(angle);
        
        cylinderVertices[i] = GLKVector3Make(x, -halfHeight, z);
        cylinderNormals[i] = GLKVector3Make(x, 0, z);
        cylinderTexCoords[i] = GLKVector2Make(percent, 0);
        
        cylinderVertices[i + numSegments] = GLKVector3Make(x, halfHeight, z);
        cylinderNormals[i + numSegments] = GLKVector3Make(x, 0, z);
        cylinderTexCoords[i + numSegments] = GLKVector2Make(percent, 1);
        
        cylinderVertices[i + numSegments * 2] = GLKVector3Make(x, -halfHeight, z);
        cylinderNormals[i + numSegments * 2] = GLKVector3Make(0, -1, 0);
        cylinderTexCoords[i + numSegments * 2] = GLKVector2Make(percent, 0);
        
        cylinderVertices[i + numSegments * 3] = GLKVector3Make(x, halfHeight, z);
        cylinderNormals[i + numSegments * 3] = GLKVector3Make(0, 1, 0);
        cylinderTexCoords[i + numSegments * 3] = GLKVector2Make(percent, 1);
        
        numCylinderVertices += 4;
        angle += angleIncrement;
        percent += percentIncrement;
    }
    
    cylinderVertices[numCylinderVertices] = GLKVector3Make(0, -halfHeight, 0);
    cylinderNormals[numCylinderVertices] = GLKVector3Make(0, -1, 0);
    cylinderTexCoords[numCylinderVertices] = GLKVector2Make(0, 0);
    numCylinderVertices += 1;
    
    cylinderVertices[numCylinderVertices] = GLKVector3Make(0, halfHeight, 0);
    cylinderNormals[numCylinderVertices] = GLKVector3Make(0, 1, 0);
    cylinderTexCoords[numCylinderVertices] = GLKVector2Make(0, 0);
    numCylinderVertices += 1;
    
    NSLog(@"There should be %d vertices and there are actually %d vertices", (numSegments * 2 * 2 + 2), numCylinderVertices);
}

static void createCylinderIndices(int numSegments)
{
    assert(cylinderVertices != NULL && cylinderNormals != NULL && cylinderTexCoords != NULL);
    assert(cylinderIndices == NULL);
    
    // Two triangles per outer segment, and one per segment on the top and bottom
    numCylinderTriangles = numSegments * 2 * 2;
    numCylinderIndices = numCylinderTriangles * 3;
    cylinderIndices = (int *)malloc(numCylinderIndices * sizeof(int));
    
    int numIndicesPerSegment = 3 * 2 * 2;
    for (int i = 0; i < numSegments; i++)
    {
        int baseIndex = i * numIndicesPerSegment;
        
        cylinderIndices[baseIndex] = i;
        cylinderIndices[baseIndex + 1] = numSegments + i;
        cylinderIndices[baseIndex + 2] = (i + 1) % numSegments;

        cylinderIndices[baseIndex + 3] = numSegments + i;
        cylinderIndices[baseIndex + 4] = numSegments + ((i + 1) % numSegments);
        cylinderIndices[baseIndex + 5] = (i + 1) % numSegments;

        cylinderIndices[baseIndex + 6] = i;
        cylinderIndices[baseIndex + 7] = numCylinderVertices - 2;
        cylinderIndices[baseIndex + 8] = (i + 1) % numSegments;
        
        cylinderIndices[baseIndex + 9] = numSegments + i;
        cylinderIndices[baseIndex + 10] = numCylinderVertices - 1;
        cylinderIndices[baseIndex + 11] = numSegments + ((i + 1) % numSegments);
    }
}

static void createCylinder(int numSegments, float width, float height)
{
    createCylinderVertices(numSegments, width, height);
    createCylinderIndices(numSegments);
}

- (id)init
{
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            int numSegments = 8;
            float width = 1.0;
            float height = 1.0;
            createCylinder(numSegments, width, height);
        });
        
//        _cylinder = [SCNCylinder cylinderWithRadius:0.5 height:1.0];
        
        _indexDataSize = 1 * sizeof(int);
        _indexData = (int *)malloc(_indexDataSize);
        
        _vertexDataSize = 1 * sizeof(SCNVector3);
        _vertexData = (SCNVector3 *)malloc(_vertexDataSize);

        _normalDataSize = 1 * sizeof(SCNVector3);
        _normalData = (SCNVector3 *)malloc(_normalDataSize);

        _texCoordDataSize = 1 * sizeof(CGPoint);
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
//    for (int i = 0; i < _cylinder.geometryElementCount; i++)
//    {
//        SCNGeometryElement *geometryElement = [_cylinder geometryElementAtIndex:i];
//        assert(geometryElement.primitiveType == SCNGeometryPrimitiveTypeTriangles && geometryElement.bytesPerIndex == 2);
//        // We know that SCNCylinder uses shorts for its indices
//        short *elementData = (short *)[geometryElement.data bytes];
//        // We know that SCNCylinders use GL_TRIANGLES, so there are 3 indices per primitive
//        for (int i = 0; i < geometryElement.primitiveCount * 3; i++)
//    {
//        int newIndex = elementData[i] + _numVertices;
//        addInt(newIndex, &_indexData, &_indexDataSize, &_numIndices);
//    }
//}

    for (int i = 0; i < numCylinderIndices; i++)
    {
        int newIndex = cylinderIndices[i] + _numVertices;
        addInt(newIndex, &_indexData, &_indexDataSize, &_numIndices);
    }


//    NSArray *vertexSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
//    assert([vertexSources count] == 1);
//    for (SCNGeometrySource *source in vertexSources) {
//        assert(source.bytesPerComponent == 4);
//        // We use GLKVector3 here for two reasons: 1) It's got floats intead of doubles (which SCNVector3 has), so it fits the data, and 2) it's easier to transform
//        GLKVector3 *sourceData = (GLKVector3 *)[source.data bytes];
//        for (int i = 0; i < source.vectorCount; i++)
//        {
//            GLKVector3 vertex = sourceData[i];
//            GLKVector4 translatableVertex = GLKVector4MakeWithVector3(vertex, 1.0);
//            GLKVector4 transformedVertex = GLKMatrix4MultiplyVector4(transform, translatableVertex);
//            addVector(GLKVector3MakeWithArray(transformedVertex.v), &_vertexData, &_vertexDataSize, &_numVertices);
//        }
//    }


    
    bool isInvertible;
    GLKMatrix4 normalTransform = GLKMatrix4Transpose(GLKMatrix4Invert(transform, &isInvertible));
    NSAssert(isInvertible, @"Transform was not invertible!");
//    NSArray *normalSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticNormal];
//    assert([normalSources count] == 1);
//    for (SCNGeometrySource *source in normalSources) {
//        // We use GLKVector3 here for two reasons: 1) It's got floats intead of doubles (which SCNVector3 has), so it fits the data, and 2) it's easier to transform
//        GLKVector3 *sourceData = (GLKVector3 *)[source.data bytes];
//        for (int i = 0; i < source.vectorCount; i++)
//        {
//            GLKVector3 normal = sourceData[i];
//            GLKVector3 transformedNormal = GLKMatrix4MultiplyVector3(normalTransform, normal);
//            addVector(transformedNormal, &_normalData, &_normalDataSize, &_numNormals);
//        }
//    }

    
    for (int i = 0; i < numCylinderVertices; i++)
    {
        GLKVector3 vertex = cylinderVertices[i];
        GLKVector4 translatableVertex = GLKVector4MakeWithVector3(vertex, 1.0);
        GLKVector4 transformedVertex = GLKMatrix4MultiplyVector4(transform, translatableVertex);
        addVector(GLKVector3MakeWithArray(transformedVertex.v), &_vertexData, &_vertexDataSize, &_numVertices);

        GLKVector3 normal = cylinderNormals[i];
        GLKVector3 transformedNormal = GLKMatrix4MultiplyVector3(normalTransform, normal);
        addVector(transformedNormal, &_normalData, &_normalDataSize, &_numNormals);

        GLKVector2 texCoord = cylinderTexCoords[i];
        addPoint(texCoord, &_texCoordData, &_texCoordDataSize, &_numTexCoords);
    }

    
    
//    NSArray *texCoordSources = [_cylinder geometrySourcesForSemantic:SCNGeometrySourceSemanticTexcoord];
//    assert([texCoordSources count] == 1);
//    for (SCNGeometrySource *source in texCoordSources) {
//        CGPoint *sourceData = (CGPoint *)[source.data bytes];
//        for (int i = 0; i < source.vectorCount; i++)
//        {
//            CGPoint texCoord = sourceData[i];
//            addPoint(texCoord, &_texCoordData, &_texCoordDataSize, &_numTexCoords);
//        }
//    }

    
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

static void addPoint(GLKVector2 point, CGPoint **data, int *inOutDataSize, int *inOutNumVectors)
{
    if (*inOutNumVectors * sizeof(CGPoint) >= *inOutDataSize)
    {
        CGPoint *largerData = (CGPoint *)realloc(*data, *inOutDataSize * 2);
        assert(largerData != NULL);
        *data = largerData;
        *inOutDataSize = *inOutDataSize * 2;
    }
    (*data)[*inOutNumVectors] = CGPointMake(point.x, point.y);
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
