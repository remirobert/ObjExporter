//
//  Exporter.m
//  IKTest
//
//  Created by Remi Robert on 10/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import "Exporter.h"
#import "Vertex.h"
#import "Primitive.h"

@interface Exporter()
@property (nonatomic, strong) NSMutableString *content;
@property (nonatomic, strong) NSMutableArray *childrens;
@property (nonatomic, strong) NSMutableArray *vertrices;
@property (nonatomic, strong) NSMutableArray *primitives;
@end

@implementation Exporter

- (void)geometryElements:(SCNNode *)node verticesData:(SCNVector3 **)tab {
    NSLog(@"NODE name geometry elements : %@", node.name);
    
    
    NSLog(@"euleur angle : %f %f %f", node.presentationNode.eulerAngles.x, node.presentationNode.eulerAngles.y, node.presentationNode   .eulerAngles.z);

    self.primitives = [[NSMutableArray alloc] init];
    
    for (int indexElement = 0; indexElement < node.geometry.geometryElementCount; indexElement++) {
        SCNGeometryElement *currentElement = [node.geometry geometryElementAtIndex:indexElement];
        
        NSLog(@"\n");
        NSLog(@"type ; : %ld", (long)currentElement.primitiveType);
        NSLog(@"bytes per index : %ld", (long)currentElement.bytesPerIndex);
        NSLog(@"number element : %ld", (long)currentElement.primitiveCount);
        NSLog(@"data lenght : %lu", (unsigned long)currentElement.data.length);

        //[self.content appendFormat:[NSString stringWithFormat:@"\ng %@\n", ((SCNNode *)[self.childrens objectAtIndex:indexElement]).name]];
        
        //NSLog(@"test data convertor : %u", value);
        
        
        NSMutableString *contentSecond = [[NSMutableString alloc] init];
        
        
        NSMutableArray *currentContent = [[NSMutableArray alloc] init];
        
        for (int index = 0; index < currentElement.data.length; index += currentElement.bytesPerIndex * 3) {
            ushort buff[3] = {0, 0, 0};
            [currentElement.data getBytes:&buff range:NSMakeRange(index, currentElement.bytesPerIndex)];
            [currentElement.data getBytes:&buff[1] range:NSMakeRange(index + currentElement.bytesPerIndex, currentElement.bytesPerIndex)];
            [currentElement.data getBytes:&buff[2] range:NSMakeRange(index + currentElement.bytesPerIndex * 2, currentElement.bytesPerIndex)];

            
            //NSLog(@"[%d]->[%lu]      current value : %u    ", index, index + currentElement.bytesPerIndex, buff[0]);
            //printf("f %u %u %u\n", buff[0] + 1, buff[1] + 1, buff[2] + 1);
            [contentSecond appendFormat:@"f %u %u %u\n", buff[0] + 1, buff[1] + 1, buff[2] + 1];
            
            NSLog(@"------------> %u %u %u", buff[0] + 1, buff[1] + 1, buff[2] + 1);
            
            Primitive *newPrimitive = [[Primitive alloc] init];
            newPrimitive.x = buff[0] + 1;
            newPrimitive.y = buff[1] + 1;
            newPrimitive.z = buff[2] + 1;

            [currentContent addObject:newPrimitive];
//            [currentContent addObject:newVertex(buff[0] + 1, buff[1] + 1, buff[2] + 1)];
            
//            tab[buff[0]].x *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.x;
//            tab[buff[0]].y *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.y;
//            tab[buff[0]].z *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.z;
//            
//            tab[buff[1]].x *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.x;
//            tab[buff[1]].y *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.y;
//            tab[buff[1]].z *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.z;
//
//            tab[buff[2]].x *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.x;
//            tab[buff[2]].y *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.y;
//            tab[buff[2]].z *= ((SCNNode *)[self.childrens objectAtIndex:indexElement]).presentationNode.eulerAngles.z;
            
            
            (*tab)[buff[0]].x = 0;
            (*tab)[buff[0]].y = 0;
            (*tab)[buff[0]].z = 0;
        }
        
        [self.primitives addObject:currentContent];
        
        //[self.content appendString:contentSecond];
        
        
        
//        for (int indexPrimitive = 0; indexPrimitive < currentElement.primitiveCount; indexPrimitive ++) {
//            uint array[3];
//            memset(array, 0, 3);
//            
//            [currentElement.data getBytes:&array range:NSMakeRange(indexPrimitive * (currentElement.bytesPerIndex * currentElement.primitiveType), (currentElement.bytesPerIndex * (currentElement.bytesPerIndex * currentElement.primitiveType)))];
//            
//            NSLog(@"currentelement : %u %u %u", array[0], array[1], array[2]);
//        }
    }
}

- (SCNVector3 *)vertices:(SCNNode *)node {
    // Get the vertex sources
    NSArray *vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    
    // Get the first source
    SCNGeometrySource *vertexSource = vertexSources[0]; // TODO: Parse all the sources
    
    NSInteger stride = vertexSource.dataStride; // in bytes
    NSInteger offset = vertexSource.dataOffset; // in bytes
    
    NSInteger componentsPerVector = vertexSource.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * vertexSource.bytesPerComponent;
    NSInteger vectorCount = vertexSource.vectorCount;
    
    SCNVector3 *vertices = malloc(sizeof(SCNVector3) * vectorCount);//[vectorCount]; // A new array for vertices
    
    // for each vector, read the bytes
    for (NSInteger i=0; i<vectorCount; i++) {
        
        // Assuming that bytes per component is 4 (a float)
        // If it was 8 then it would be a double (aka CGFloat)
        float vectorData[componentsPerVector];
        
        // The range of bytes for this vector
        NSRange byteRange = NSMakeRange(i*stride + offset, // Start at current stride + offset
                                        bytesPerVector);   // and read the lenght of one vector
        
        // Read into the vector data buffer
        [vertexSource.data getBytes:&vectorData range:byteRange];
        
        // At this point you can read the data from the float array
        float x = vectorData[0];
        float y = vectorData[1];
        float z = vectorData[2];
        
        // ... Maybe even save it as an SCNVector3 for later use ...
        vertices[i] = SCNVector3Make(x, y, z);

        if (!self.vertrices) {
            self.vertrices = [[NSMutableArray alloc] init];
        }
        
        [self.vertrices addObject:[Vertex instance:SCNVector3Make(x, y, z)]];
//        [self.content appendFormat:@"v %f %f %f\n", x, y, z];
        
        // ... or just log it
        
        //printf("v %f %f %f\n", x, y, z);
    }
    return vertices;
}

- (void)materials:(SCNNode *)node {
    NSLog(@"current material : %@", node.geometry.materials);
}

- (void)geometry:(SCNNode *)node {
    if (node.geometry) {
        NSLog(@"geometry elements : %ld", (long)node.geometry.geometryElementCount);
        NSLog(@"rotation element : %f %f %f %f", node.presentationNode.rotation.x, node.presentationNode.rotation.y, node.presentationNode.rotation.z, node.presentationNode.rotation.w);
        SCNVector3 *vect = [self vertices:node];
        [self geometryElements:node verticesData:&vect];
                
        //[self materials:node.presentationNode];
        NSLog(@"curren geometry : %@", node.geometry);
    }
}

- (void)loopChildObj:(NSArray *)childs {
    for (SCNNode *currentChildNode in childs) {
        NSLog(@"current child name : [%@]", currentChildNode.name);
        if (currentChildNode.name) {
            [self geometry:currentChildNode.presentationNode];
            [self loopChildObj:currentChildNode.presentationNode.childNodes];
        }
        
        NSLog(@"current node : %@", currentChildNode.name);
    }
}

- (void)generateOBJ:(SCNScene *)scene {
    NSLog(@"start loop");
    
    self.childrens = [[NSMutableArray alloc] init];

    [self.childrens addObject:[scene.rootNode childNodeWithName:@"Arm" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"Cube" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"Armature" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"RootBone" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"BoneA" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"BoneB" recursively:true]];
    [self.childrens addObject:[scene.rootNode childNodeWithName:@"BoneC" recursively:true]];
    
    self.content = [[NSMutableString alloc] init];
    [self.content appendFormat:@"\n"];
    SCNNode *node = [scene.rootNode childNodeWithName:@"Arm" recursively:true];

    
    
    
    NSLog(@"%lu", (unsigned long)node.childNodes.count);
    [self loopChildObj:node.presentationNode.childNodes];
    
    //NSLog(@"content file : %@", self.content);


    self.content = [[NSMutableString alloc] init];
    
//    NSLog(@"%@", self.vertrices);
//    NSLog(@"%@", self.primitives);
    

//    for (int indexElement = 0; indexElement < self.childrens.count; indexElement++) {
//        for (NSArray *primitives in self.primitives) {
//            for (Primitive *currentPrimitive in primitives) {
//
//
//                SCNNode *currentNode = [self.childrens objectAtIndex:indexElement];
//
//                NSLog(@"[]]]]]]]]]]]]]]]]]]] -> %f %f %f", currentNode.eulerAngles.x, currentNode.eulerAngles.y, currentNode.eulerAngles.z);
//                
//                if (currentPrimitive.x < self.vertrices.count) {
//                    Vertex *currentVertex1 = [self.vertrices objectAtIndex:currentPrimitive.x];
//                    currentVertex1.x += currentNode.presentationNode.eulerAngles.x;
//                    currentVertex1.y += currentNode.presentationNode.eulerAngles.y;
//                    currentVertex1.z += currentNode.presentationNode.eulerAngles.z;
//                }
//                
//                if (currentPrimitive.y < self.vertrices.count) {
//                    Vertex *currentVertex2 = [self.vertrices objectAtIndex:currentPrimitive.y];
//                    currentVertex2.x += currentNode.presentationNode.eulerAngles.x;
//                    currentVertex2.y += currentNode.presentationNode.eulerAngles.y;
//                    currentVertex2.z += currentNode.presentationNode.eulerAngles.z;
//                }
//
//                if (currentPrimitive.z < self.vertrices.count) {
//                    Vertex *currentVertex3 = [self.vertrices objectAtIndex:currentPrimitive.z];
//                    currentVertex3.x += currentNode.presentationNode.eulerAngles.x;
//                    currentVertex3.y += currentNode.presentationNode.eulerAngles.y;
//                    currentVertex3.z += currentNode.presentationNode.eulerAngles.z;
//                }
//
//            }
//        }
//    }

    
    for (Vertex *currentVertrices in self.vertrices) {
        [self.content appendFormat:@"v %f %f %f\n", currentVertrices.x, currentVertrices.y, currentVertrices.z];
    }
    
    for (NSArray *primitives in self.primitives) {
        [self.content appendFormat:@"\ng ok\n"];
        for (Primitive *currentPrimitive in primitives) {
            [self.content appendFormat:@"f %u %u %u\n", currentPrimitive.x, currentPrimitive.y, currentPrimitive.z];
        }
    }
    
    NSLog(@"content : \n%@", self.content);
}

@end
