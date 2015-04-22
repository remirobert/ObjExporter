//
//  Vertex.h
//  IKTest
//
//  Created by Remi Robert on 13/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@interface Vertex : NSObject

@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float z;

+ (instancetype) instance:(SCNVector3)v;

@end
