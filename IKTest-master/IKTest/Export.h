//
//  Export.h
//  IKTest
//
//  Created by Remi Robert on 21/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface Export : NSObject

+ (void)exportGeometry:(SCNScene *)scene;

@end
