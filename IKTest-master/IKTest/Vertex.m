//
//  Vertex.m
//  IKTest
//
//  Created by Remi Robert on 13/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import "Vertex.h"

@implementation Vertex

+ (instancetype) instance:(SCNVector3)v {
    Vertex *newVertex = [[Vertex alloc] init];
    newVertex.x = v.x;
    newVertex.y = v.y;
    newVertex.z = v.z;
    return newVertex;
}

@end
