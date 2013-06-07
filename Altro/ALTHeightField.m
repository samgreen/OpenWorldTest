//
//  ALTHeightField.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 6/2/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

// This code started off courtesy of "abes", see: https://devforums.apple.com/message/709572#709572

#import "ALTHeightField.h"
#import "SKRMath.h"
#import <GLKit/GLKMath.h>

@implementation ALTHeightField
{
    float xSpacing, zSpacing;
    unsigned vertexCount, elementCount;
    unsigned rows;
    unsigned columns;
    float *heights;
}

// creates a grid of vertices and maps their location to the texture maped on heightfield
- (void) createVertices: (SCNVector3 *)vertices texCoords:(CGPoint *)texCoords normals:(SCNVector3 *)normals
{
    float halfWidth = columns * xSpacing / 2;
    float halfLength = rows * zSpacing / 2;
    for (int z = 0; z < rows; z++) {
        for (int x = 0; x < columns; x++) {
            float xPos = x * xSpacing - halfWidth;
            float zPos = z * zSpacing - halfLength;
            float height = heights[x+z*columns];
            vertices[x + z*columns] = SCNVector3Make(xPos, height, zPos);
            texCoords[x + z*columns] = CGPointMake(((float)x)/columns, ((float)z)/rows);
        }
    }
    
    /* For normal calculation, we will name our neighbor vertices like so:
     *     +z
     *      A
     * -x B V C +x
     *      D
     *     -z
     */
    for (int z = 0; z < rows; z++) {
        for (int x = 0; x < columns; x++) {
            int prevXIndex = x % columns == 0 ? x : x - 1;
            int nextXIndex = x % columns == columns - 1 ? x : x + 1;

            int prevZIndex = z % rows == 0 ? z : z - 1;
            int nextZIndex = z % rows == rows - 1 ? z : z + 1;
            
            GLKVector3 B = GLKVector3MakeWithSCNVector3(vertices[prevXIndex + z * columns]);
            GLKVector3 C = GLKVector3MakeWithSCNVector3(vertices[nextXIndex + z * columns]);
            GLKVector3 D = GLKVector3MakeWithSCNVector3(vertices[x + prevZIndex * columns]);
            GLKVector3 A = GLKVector3MakeWithSCNVector3(vertices[x + nextZIndex * columns]);
            GLKVector3 V = GLKVector3MakeWithSCNVector3(vertices[x + z * columns]);
            
            GLKVector3 BV = GLKVector3Subtract(B, V);
            GLKVector3 CV = GLKVector3Subtract(C, V);
            GLKVector3 DV = GLKVector3Subtract(D, V);
            GLKVector3 AV = GLKVector3Subtract(A, V);
            GLKVector3 BANormal = GLKVector3CrossProduct(BV, AV);
            GLKVector3 ACNormal = GLKVector3CrossProduct(AV, CV);
            GLKVector3 CDNormal = GLKVector3CrossProduct(CV, DV);
            GLKVector3 DBNormal = GLKVector3CrossProduct(DV, BV);
            
            GLKVector3 sumOfNormals = GLKVector3Add(BANormal, GLKVector3Add(ACNormal, GLKVector3Add(CDNormal, DBNormal)));
            GLKVector3 normal = GLKVector3Normalize(GLKVector3DivideScalar(sumOfNormals, 4.0));
            
            normals[x + z * columns] = SCNVector3Make(normal.x, normal.y, normal.z);
        }
    }
}

// creates a trianglestrip with degenerate triangles
// see the many tutorials online for details

- (void) createElements: (int *)elements
{
    int index = 0;
    for (int z = 0; z < rows-1; z++) {
        // Even rows move left to right, odd rows move right to left.
        if (z%2 == 0) {
            int x;
            for (x = 0; x < columns; x++) {
                elements[index++] = x + (z*columns);
                elements[index++] = x + (z*columns) + columns;
            }
            
            // Degenerate case
            if (z != rows - 2) elements[index++] = (x-1)+(z*columns);
        } else {
            int x;
            for (x = columns-1; x >= 0; x--) {
                elements[index++] = x + (z*columns);
                elements[index++] = x + (z*columns) + columns;
            }
            
            // Degenerate gase
            if (z != columns-2) elements[index++] = (x+1)+(z*columns);
        }
    }
}

- (id) initWithRows:(int)r columns:(int)c heights:(float *)h xspace:(float)xs zspace:(float)zs
{
    if ([super init]) {
        rows = r;
        columns = c;
        xSpacing = xs;
        zSpacing = zs;
        heights = h;
        vertexCount = rows*columns;
        elementCount = 2*columns*(rows-1) + (rows - 2);
        
        // create vertices
        SCNVector3 *vertices = malloc(vertexCount*sizeof(SCNVector3));
        CGPoint *texCoords = malloc(vertexCount*sizeof(CGPoint));
        SCNVector3 *normals = malloc(vertexCount*sizeof(SCNVector3));
        
        [self createVertices:vertices texCoords:texCoords normals:normals];
        SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:vertexCount];
        SCNGeometrySource *texSource = [SCNGeometrySource geometrySourceWithTextureCoordinates:texCoords count:vertexCount];
        SCNGeometrySource *normalsSource = [SCNGeometrySource geometrySourceWithNormals:normals count:vertexCount];
        
        // create element ordering
        int *elements = malloc(elementCount*sizeof(unsigned));
        [self createElements: elements];
        
        // encoder elements as NSData
        NSData *elementsData = [NSData dataWithBytes:elements length:elementCount*sizeof(unsigned)];
        
        SCNGeometryElement *geometryElement = [SCNGeometryElement geometryElementWithData:elementsData primitiveType:SCNGeometryPrimitiveTypeTriangleStrip primitiveCount:elementCount-2 bytesPerIndex:sizeof(unsigned)];
        
        // create geometry from sources and elements
        self.geometry = [SCNGeometry geometryWithSources:@[vertexSource, texSource, normalsSource] elements:@[geometryElement]];
        
        // free allocated memory
        free(vertices);
        free(elements);
        free(texCoords);
    }
    
    return self;
}

- (void)dealloc
{
    free(heights);
}

- (float)heightAt:(GLKVector3)location
{
    float halfWidth = columns * xSpacing / 2;
    float halfLength = rows * zSpacing / 2;
    
    GLKVector3 locationInGrid = GLKVector3Add(location, GLKVector3Make(halfWidth, 0, halfLength));

    int columnAIndex = CLAMP(floor((locationInGrid.x) / xSpacing), 0, columns - 1);
    int columnBIndex = CLAMP(columnAIndex + 1, 0, columns - 1);
    int rowAIndex = CLAMP(floor((locationInGrid.z) / zSpacing), 0, rows - 1);
    int rowBIndex = CLAMP(rowAIndex + 1, 0, rows - 1);
    
    float x = MAX(0, MIN(1, (locationInGrid.x - (columnAIndex * xSpacing)) / xSpacing));
    float z = MAX(0, MIN(1, (locationInGrid.z - (rowAIndex * zSpacing)) / zSpacing));
    
    float x0y0Height = heights[columnAIndex + rowAIndex * columns];
    float x1y0Height = heights[columnBIndex + rowAIndex * columns];
    float x0y1Height = heights[columnAIndex + rowBIndex * columns];
    float x1y1Height = heights[columnBIndex + rowBIndex * columns];
    
    float interpolatedHeight = (x0y0Height * (1 - x) * (1 - z) +
                                x1y0Height * x * (1 - z) +
                                x0y1Height * (1 - x) * z +
                                x1y1Height * x * z);
    
    NSLog(@"cA: %d, cB: %d, rA: %d, rB: %d", columnAIndex, columnBIndex, rowAIndex, rowBIndex);
    NSLog(@"x0y0: %f, x1y0: %f, x0y1: %f, x1y1: %f", x0y0Height, x1y0Height, x0y1Height, x1y1Height);
    NSLog(@"x: %f, z: %f, h: %f", x, z, interpolatedHeight);
    
    return interpolatedHeight;
}

@end
