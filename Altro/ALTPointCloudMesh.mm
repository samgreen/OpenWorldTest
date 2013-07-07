//
//  ALTPointCloudMesh.m
//  OpenWorldTest
//
//  Created by Mike Rotondo on 7/6/13.
//  Copyright (c) 2013 Taka Taka. All rights reserved.
//

#import "ALTPointCloudMesh.h"
#include <pcl/point_types.h>
#include <pcl/search/kdtree.h>
#include <pcl/features/normal_3d.h>
#include <pcl/surface/concave_hull.h>
#import <GLKit/GLKMath.h>
#import <SceneKit/SceneKit.h>

static void addSphereToCloud(pcl::PointCloud<pcl::PointXYZ>::Ptr cloud, float radius, float centerX, float centerY, float centerZ, int numPoints)
{
    for (int i = 0; i < numPoints; ++i)
    {
        float azimuth = 2 * M_PI * (float)rand() / RAND_MAX;
        float inclination = M_PI * (float)rand() / RAND_MAX;
        float x = centerX + radius * sinf(inclination) * cosf(azimuth);
        float y = centerY + radius * sinf(inclination) * sinf(azimuth);
        float z = centerZ + radius * cosf(inclination);
        
        cloud->push_back(pcl::PointXYZ(x, y, z));
    }
}

static pcl::PointCloud<pcl::PointXYZ>::Ptr createCloud()
{
    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud = pcl::PointCloud<pcl::PointXYZ>::Ptr(new pcl::PointCloud<pcl::PointXYZ>);
    
    addSphereToCloud(cloud, 1.0, 0.0, 0.0, 0.0, 1000);
    cloud->is_dense = true;
    
    return cloud;
}

static pcl::ConcaveHull<pcl::PointXYZ> generateHullFromCloud(pcl::PointCloud<pcl::PointXYZ>::Ptr cloud)
{
    // Create search tree*
    pcl::search::KdTree<pcl::PointXYZ>::Ptr tree (new pcl::search::KdTree<pcl::PointXYZ>);
    tree->setInputCloud (cloud);
    
    // CONCAVE HULL
    pcl::ConcaveHull<pcl::PointXYZ> hull;
//    hull.setKeepInformation(true);
    hull.setAlpha (0.19);
    
    // Get result
    hull.setInputCloud (cloud);
    hull.setSearchMethod (tree);

    return hull;
}

SCNGeometry *generateGeometryFromHull(pcl::ConcaveHull<pcl::PointXYZ> hull)
{
    pcl::PolygonMesh triangles;
    hull.reconstruct (triangles);

    int numVertices = triangles.cloud.width;

    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud = pcl::PointCloud<pcl::PointXYZ>::Ptr(new pcl::PointCloud<pcl::PointXYZ>);
    pcl::fromROSMsg(triangles.cloud, *cloud);

    // Normal estimation*
    pcl::NormalEstimation<pcl::PointXYZ, pcl::Normal> n;
    pcl::PointCloud<pcl::Normal>::Ptr cloudNormals (new pcl::PointCloud<pcl::Normal>);
    pcl::search::KdTree<pcl::PointXYZ>::Ptr tree (new pcl::search::KdTree<pcl::PointXYZ>);
    tree->setInputCloud (cloud);
    n.setInputCloud (cloud);
    n.setSearchMethod (tree);
    n.setKSearch (20);
    n.compute (*cloudNormals);

    pcl::PointCloud<pcl::PointNormal>::Ptr cloudWithNormals (new pcl::PointCloud<pcl::PointNormal>);
    pcl::concatenateFields (*cloud, *cloudNormals, *cloudWithNormals);
    
    int verticesSize = numVertices * sizeof(SCNVector3);
    SCNVector3 *vertices = (SCNVector3 *)malloc(verticesSize);
    SCNVector3 *normals = (SCNVector3 *)malloc(verticesSize);
    int numVerticesAdded = 0;
    for (std::vector<pcl::PointNormal>::const_iterator it = cloudWithNormals->points.begin(); it != cloudWithNormals->points.end(); ++ it)
    {
        pcl::PointNormal point = *it;
        SCNVector3 vertex = SCNVector3Make(point.x, point.y, point.z);
        SCNVector3 normal = SCNVector3Make(point.normal_x, point.normal_y, point.normal_z);
        vertices[numVerticesAdded] = vertex;
        normals[numVerticesAdded] = normal;
        ++numVerticesAdded;
        
//        NSLog(@"Here's a vertex: %f, %f, %f", vertex.x, vertex.y, vertex.z);
//        NSLog(@"Here's a normal: %f, %f, %f", normal.x, normal.y, normal.z);
    }

    
    unsigned long numIndices = triangles.polygons.size() * 3;
    unsigned long indicesSize = numIndices * sizeof(uint32_t);
    uint32_t *indices = (uint32_t *)malloc(indicesSize);
    int numIndicesAdded = 0;
    for (std::vector<pcl::Vertices>::iterator polygon_it = triangles.polygons.begin(); polygon_it != triangles.polygons.end(); ++polygon_it)
    {
        pcl::Vertices polygon = *polygon_it;
        for (std::vector<uint32_t>::iterator index_it = polygon.vertices.begin(); index_it != polygon.vertices.end(); ++index_it)
        {
            uint32_t index = *index_it;
            indices[numIndicesAdded] = index;
            ++numIndicesAdded;

//            NSLog(@"Got an index; %ud", index);
        }
    }
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:indices length:indicesSize]
                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles primitiveCount:numIndices / 3
                                                                bytesPerIndex:4];
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:numVertices];
    SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithNormals:normals count:numVertices];
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource] elements:@[element]];
    
    free(vertices);
    free(normals);
    free(indices);
    
    return geometry;
}

SCNGeometry *ALTPointCloudMeshCreateSphere()
{
    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud = createCloud();
    pcl::ConcaveHull<pcl::PointXYZ> hull = generateHullFromCloud(cloud);
    SCNGeometry *geometry = generateGeometryFromHull(hull);
    return geometry;
}
