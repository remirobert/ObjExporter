//
//  Exporter.h
//  IKTest
//
//  Created by Remi Robert on 10/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface Exporter : NSObject

- (void)generateOBJ:(SCNScene *)scene;

@end
