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

@implementation ALTPointCloudMesh
{
    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud;
}

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


- (id)init
{
    self = [super init];
    if (self) {
        cloud = pcl::PointCloud<pcl::PointXYZ>::Ptr(new pcl::PointCloud<pcl::PointXYZ>);
        
        addSphereToCloud(cloud, 1.0, -0.45, -0.45, 0.0, 1000);
        addSphereToCloud(cloud, 1.0, 0.45, -0.45, 0.0, 1000);
        addSphereToCloud(cloud, 1.0, 0.0, 0.45, 0.0, 1000);
        cloud->is_dense = true;
        
        // Normal estimation*
        pcl::NormalEstimation<pcl::PointXYZ, pcl::Normal> n;
        pcl::PointCloud<pcl::Normal>::Ptr normals (new pcl::PointCloud<pcl::Normal>);
        pcl::search::KdTree<pcl::PointXYZ>::Ptr tree (new pcl::search::KdTree<pcl::PointXYZ>);
        tree->setInputCloud (cloud);
        n.setInputCloud (cloud);
        n.setSearchMethod (tree);
        n.setKSearch (20);
        n.compute (*normals);
        //* normals should not contain the point normals + surface curvatures
        
        // Concatenate the XYZ and normal fields*
        pcl::PointCloud<pcl::PointNormal>::Ptr cloud_with_normals (new pcl::PointCloud<pcl::PointNormal>);
        pcl::concatenateFields (*cloud, *normals, *cloud_with_normals);
        //* cloud_with_normals = cloud + normals
        
        // Create search tree*
        pcl::search::KdTree<pcl::PointNormal>::Ptr tree2 (new pcl::search::KdTree<pcl::PointNormal>);
        tree2->setInputCloud (cloud_with_normals);
        
        // CONCAVE HULL
        pcl::ConcaveHull<pcl::PointNormal> hull;
        hull.setAlpha (0.25);
        
        // Get result
        hull.setInputCloud (cloud_with_normals);
        hull.setSearchMethod (tree2);
        
        pcl::PolygonMesh triangles;
        hull.reconstruct (triangles);
    }
    return self;
}

@end
