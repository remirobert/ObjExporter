//
//  ChildrenExporter.h
//  IKTest
//
//  Created by Remi Robert on 14/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@interface ChildrenExporter : NSObject

+ (void)exportFromScene:(SCNScene *)scene;

@end
