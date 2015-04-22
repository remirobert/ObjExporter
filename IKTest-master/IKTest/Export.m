//
//  Export.m
//  IKTest
//
//  Created by Remi Robert on 21/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import "Export.h"

@interface NodePoint : NSObject
@property (nonatomic, strong) SCNNode *node1;
@property (nonatomic, strong) SCNNode *node2;
@property (nonatomic, assign) NSInteger indiceVertex;
@property (nonatomic, assign) float weight1;
@property (nonatomic, assign) float weight2;
@end

@implementation NodePoint
@end

@interface Vertex : NSObject
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float z;
@end

@interface Primitive : NSObject
@property (nonatomic, assign) ushort x;
@property (nonatomic, assign) ushort y;
@property (nonatomic, assign) ushort z;
@end

@interface Export()
@property (nonatomic, strong) NSMutableArray *nodes;
@property (nonatomic, strong) NSMutableArray *vectrices;
@property (nonatomic, strong) NSMutableArray *primitives;
@property (nonatomic, strong) NSMutableArray *points;
@end

@implementation Export


static Vertex *newVertex(float x, float y, float z) {
    Vertex *newVertex = [Vertex new];
    newVertex.x = x;
    newVertex.y = y;
    newVertex.z = z;
    return newVertex;
}

static Primitive *newPrimitive(float x, float y, float z) {
    Primitive *newPrimitive = [Primitive new];
    newPrimitive.x = x;
    newPrimitive.y = y;
    newPrimitive.z = z;
    return newPrimitive;
}

- (NSMutableArray *)nodes {
    if (!_nodes) {
        _nodes = [NSMutableArray array];
    }
    return _nodes;
}

- (NSMutableArray *)vectrices {
    if (!_vectrices) {
        _vectrices = [NSMutableArray array];
    }
    return _vectrices;
}

- (NSMutableArray *)primitives {
    if (!_primitives) {
        _primitives = [NSMutableArray array];
    }
    return _primitives;
}

- (NSMutableArray *)points {
    if (!_points) {
        _points = [NSMutableArray array];
    }
    return _points;
}

#pragma mark primitives

- (void)parsePrimitivesSource:(SCNGeometryElement *)primitiveElement {
    NSMutableArray *currentContent = [[NSMutableArray alloc] init];
    
    [currentContent addObject:[NSString stringWithFormat:@"%@", primitiveElement]];
    
    for (int index = 0; index < primitiveElement.data.length; index += primitiveElement.bytesPerIndex * 3) {
        ushort buff[3] = {0, 0, 0};
        
        [primitiveElement.data getBytes:&buff range:NSMakeRange(index, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[1] range:NSMakeRange(index + primitiveElement.bytesPerIndex, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[2] range:NSMakeRange(index + primitiveElement.bytesPerIndex * 2, primitiveElement.bytesPerIndex)];
        
        [currentContent addObject:newPrimitive(buff[0] + 1, buff[1] + 1, buff[2] + 1)];
    }
    [self.primitives addObject:currentContent];
}

- (void)primitivesGeometry:(SCNNode *)node {
    if (!node.skinner.baseGeometry) {
        return;
    }
    for (int indexElement = 0; indexElement < node.skinner.baseGeometry.geometryElementCount; indexElement++) {
        SCNGeometryElement *currentElement = [node.skinner.baseGeometry geometryElementAtIndex:indexElement];
        if (currentElement) {
            [self parsePrimitivesSource:currentElement];
        }
    }
}

#pragma mark Vectrices

- (void)parseVertexSource:(SCNGeometrySource *)vertexSource {
    NSInteger stride = vertexSource.dataStride;
    NSInteger offset = vertexSource.dataOffset;
    
    NSInteger componentsPerVector = vertexSource.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * vertexSource.bytesPerComponent;
    NSInteger vectorCount = vertexSource.vectorCount;
    
    for (NSInteger i=0; i<vectorCount; i++) {
        float vectorData[componentsPerVector];
        
        NSRange byteRange = NSMakeRange(i*stride + offset, bytesPerVector);
        
        [vertexSource.data getBytes:&vectorData range:byteRange];
        
        float x = vectorData[0];
        float y = vectorData[1];
        float z = vectorData[2];
        
        [self.vectrices addObject:newVertex(x, y, z)];
    }
}

- (void)verticesGeometry:(SCNNode *)node {
    if (!node.skinner.baseGeometry) {
        return;
    }
    NSArray *vertexSources;
    vertexSources = [node.skinner.baseGeometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    
    if (!vertexSources) {
        return;
    }
    for (SCNGeometrySource *currentSource in vertexSources) {
        [self parseVertexSource:currentSource];
    }
}

#pragma mark weight bones

- (void)parseWeightBones:(SCNGeometrySource *)source {
    
    NSInteger stride = source.dataStride;
    NSInteger offset = source.dataOffset;
    
    NSInteger componentsPerVector = source.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * source.bytesPerComponent;
    NSInteger vectorCount = source.vectorCount;
    
    
    NSLog(@"==========WIEGHT==========");
    
    NSLog(@"bytes : %ld", (long)source.bytesPerComponent);
    NSLog(@"componenet : %ld", (long)componentsPerVector);
    NSLog(@"bytes pe index : %ld", (long)bytesPerVector);
    NSLog(@"count : %ld", (long)vectorCount);
    NSLog(@"data lenght =:  %lu", (unsigned long)source.data.length);
    NSLog(@"data stride : %ld", (long)stride);
    NSLog(@"data offset : %ld", (long)offset);
    
    for (NSInteger i=0; i < source.vectorCount; i++) {
        float vectorData[componentsPerVector];
        
        vectorData[0] = 0;
        vectorData[1] = 0;
        
        NSRange byteRange = NSMakeRange(i*stride + offset, bytesPerVector);
        
        [source.data getBytes:&vectorData range:byteRange];
        
        float x = vectorData[0];
        float y = vectorData[1];
        
        NSLog(@"current indices : %f %f", x, y);
    }
}

- (void)weightBones:(SCNNode *)node {
    NSLog(@"name node : %@", node.name);
    [self parseWeightBones:node.skinner.boneWeights];
}

#pragma mark indices bones

- (void)parseIndicesBones:(SCNGeometrySource *)source {

    NSInteger stride = source.dataStride;
    NSInteger offset = source.dataOffset;
    
    NSInteger componentsPerVector = source.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * source.bytesPerComponent;
    NSInteger vectorCount = source.vectorCount;
    
    NSLog(@"==========INDICES==========");
    
    NSLog(@"bytes : %ld", (long)source.bytesPerComponent);
    NSLog(@"componenet : %ld", (long)componentsPerVector);
    NSLog(@"bytes pe index : %ld", (long)bytesPerVector);
    NSLog(@"count : %ld", (long)vectorCount);
    NSLog(@"data lenght =:  %lu", (unsigned long)source.data.length);
    NSLog(@"data stride : %ld", (long)stride);
    NSLog(@"data offset : %ld", (long)offset);

    for (NSInteger i=0; i < source.vectorCount; i++) {
        UInt16 vectorData[componentsPerVector];
        
        vectorData[0] = 0;
        vectorData[1] = 0;
        
        NSRange byteRange = NSMakeRange(i*stride + offset, bytesPerVector);
        
        [source.data getBytes:&vectorData range:byteRange];
        
        UInt16 x = vectorData[0];
        UInt16 y = vectorData[1];
        
        NodePoint *newPoint = [NodePoint new];
        
        NSLog(@"current indices : %d %d", x, y);
    }
}

- (void)indicesBones:(SCNNode *)node {
    NSLog(@"name node : %@", node.name);
    [self parseIndicesBones:node.skinner.boneIndices];
}

#pragma mark export data

- (UInt16 *)indices:(SCNGeometrySource *)source forIndex:(NSInteger)index {
    NSInteger stride = source.dataStride;
    NSInteger offset = source.dataOffset;
    
    NSInteger componentsPerVector = source.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * source.bytesPerComponent;
    
    UInt16 *vectorData = malloc((componentsPerVector + 1) * sizeof(UInt16));
    
    NSRange byteRange = NSMakeRange(index*stride + offset, bytesPerVector);

    vectorData[0] = 0;
    vectorData[1] = 0;

    [source.data getBytes:&vectorData range:byteRange];
    return vectorData;
}

- (float *)weight:(SCNGeometrySource *)source forIndex:(NSInteger)index {
    NSInteger stride = source.dataStride;
    NSInteger offset = source.dataOffset;
    
    NSInteger componentsPerVector = source.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * source.bytesPerComponent;
    
    float *vectorData = malloc((componentsPerVector + 1) * sizeof(float));
    
    NSRange byteRange = NSMakeRange(index*stride + offset, bytesPerVector);
    
    vectorData[0] = 0;
    vectorData[1] = 0;
    
    [source.data getBytes:&vectorData range:byteRange];
    return vectorData;
}

- (void)extractData:(SCNNode *)node {
    SCNGeometrySource *indicesSource = node.skinner.boneIndices;
    SCNGeometrySource *weightSource = node.skinner.boneWeights;
    
    
    for (NSInteger index = 0; index < indicesSource.vectorCount; index++) {
        UInt16 currentIndices[indicesSource.componentsPerVector];
        float currentWeight[weightSource.componentsPerVector];
        
        
        NSRange byteRangeIndice = NSMakeRange(index * indicesSource.dataStride + indicesSource.dataOffset, indicesSource.bytesPerComponent *indicesSource.componentsPerVector);
        NSRange byteRangeWeight = NSMakeRange(index * weightSource.dataStride + weightSource.dataOffset, weightSource.bytesPerComponent * weightSource.componentsPerVector);

        
        [indicesSource.data getBytes:&currentIndices range:byteRangeIndice];
        [weightSource.data getBytes:&currentWeight range:byteRangeWeight];

        NSLog(@"indice : [%d][%d] weight : [%f][%f]", currentIndices[0], currentIndices[1], currentWeight[0], currentWeight[1]);
        
        
        NodePoint *newPoint = [NodePoint new];
        newPoint.node1 = [node.skinner.bones objectAtIndex:currentIndices[0]];
        if (currentWeight[1] != 0) {
            newPoint.node2 = [node.skinner.bones objectAtIndex:currentIndices[1]];
        }
        newPoint.weight1 = currentWeight[0];
        newPoint.weight2 = currentWeight[0];
        newPoint.indiceVertex = index;
        
        [self.points addObject:newPoint];
    }
}

- (void)exportData:(SCNNode *)node {
    [self extractData:node];
}

#pragma mark do stuff

- (void)loopChildNode:(NSArray *)children {
    for (SCNNode *node in children) {
        
        if (node.geometry) {
            [self.nodes addObject:node];
            NSLog(@"name : %@", node.name);
            for (SCNNode *n in node.skinner.bones) {
                NSLog(@"->[%@]", n.name);
            }
        }
        
        if (node.childNodes) {
            [self loopChildNode:node.childNodes];
        }
    }
}

- (void)generateFile {
    NSMutableString *content = [NSMutableString string];
    NSInteger indexNode = 0;
    
    for (Vertex *currentVertex in self.vectrices) {
        
        NodePoint *point = [self.points objectAtIndex:indexNode];
        
        //NSLog(@"current point : [%@] [%@] => %ld", point.node1.name, point.node2.name, (long)point.indiceVertex);
        
        SCNMatrix4 newMatrix = point.node1.worldTransform;
        
        if (point.node2) {
            
            
//            newMatrix.m11 = (point.node1.worldTransform.m11 * point.weight1) + (point.node2.worldTransform.m11 * point.weight2);
//            newMatrix.m12 = (point.node1.worldTransform.m12 * point.weight1) + (point.node2.worldTransform.m12 * point.weight2);
//            newMatrix.m13 = (point.node1.worldTransform.m13 * point.weight1) + (point.node2.worldTransform.m13 * point.weight2);
//
//            newMatrix.m21 = (point.node1.worldTransform.m21 * point.weight1) + (point.node2.worldTransform.m21 * point.weight2);
//            newMatrix.m22 = (point.node1.worldTransform.m22 * point.weight1) + (point.node2.worldTransform.m22 * point.weight2);
//            newMatrix.m23 = (point.node1.worldTransform.m23 * point.weight1) + (point.node2.worldTransform.m23 * point.weight2);
//
//            newMatrix.m31 = (point.node1.worldTransform.m31 * point.weight1) + (point.node2.worldTransform.m31 * point.weight2);
//            newMatrix.m32 = (point.node1.worldTransform.m32 * point.weight1) + (point.node2.worldTransform.m32 * point.weight2);
//            newMatrix.m33 = (point.node1.worldTransform.m33 * point.weight1) + (point.node2.worldTransform.m33 * point.weight2);
            
            
//            newMatrix.m11 = (point.node1.worldTransform.m11 + point.node2.worldTransform.m11) / 2;
//            newMatrix.m12 = (point.node1.worldTransform.m12 + point.node2.worldTransform.m12) / 2;
//            newMatrix.m13 = (point.node1.worldTransform.m13 + point.node2.worldTransform.m13) / 2;
//            
//            newMatrix.m21 = (point.node1.worldTransform.m21 + point.node2.worldTransform.m21) / 2;
//            newMatrix.m22 = (point.node1.worldTransform.m22 + point.node2.worldTransform.m22) / 2;
//            newMatrix.m23 = (point.node1.worldTransform.m23 + point.node2.worldTransform.m23) / 2;
//            
//            newMatrix.m31 = (point.node1.worldTransform.m31 + point.node2.worldTransform.m31) / 2;
//            newMatrix.m32 = (point.node1.worldTransform.m32 + point.node2.worldTransform.m32) / 2;
//            newMatrix.m33 = (point.node1.worldTransform.m33 + point.node2.worldTransform.m33) / 2;
//            
//            newMatrix.m41 = (point.node1.worldTransform.m41 + point.node2.worldTransform.m41) / 2;
//            newMatrix.m42 = (point.node1.worldTransform.m42 + point.node2.worldTransform.m42) / 2;
//            newMatrix.m43 = (point.node1.worldTransform.m43 + point.node2.worldTransform.m43) / 2;
//
        }
        
        
        NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f][%f %f %f]", point.node1.name, newMatrix.m11, newMatrix.m12, newMatrix.m13, newMatrix.m21, newMatrix.m22, newMatrix.m23, newMatrix.m31, newMatrix.m32, newMatrix.m33, newMatrix.m41, newMatrix.m42, newMatrix.m43);
        
        Vertex *new = [Vertex new];
        
        new.x = (newMatrix.m11 * currentVertex.x) + (newMatrix.m21 * currentVertex.y) + (newMatrix.m31 * currentVertex.z) + newMatrix.m41;
        new.y = (newMatrix.m12 * currentVertex.x) + (newMatrix.m22 * currentVertex.y) + (newMatrix.m32 * currentVertex.z) + newMatrix.m42;
        new.z = (newMatrix.m13 * currentVertex.x) + (newMatrix.m23 * currentVertex.y) + (newMatrix.m33 * currentVertex.z) + newMatrix.m43;

        float w = (newMatrix.m14 * currentVertex.x) + (newMatrix.m24 * currentVertex.y) + (newMatrix.m34 * currentVertex.z) + newMatrix.m44;
        
        new.x = new.x / w;
        new.y = new.y / w;
        new.z = new.z / w;
        
        
        if (point.node2) {
            Vertex *new2 = [Vertex new];
            newMatrix = point.node2.worldTransform;
            
            new2.x = (newMatrix.m11 * currentVertex.x) + (newMatrix.m21 * currentVertex.y) + (newMatrix.m31 * currentVertex.z) + newMatrix.m41;
            new2.y = (newMatrix.m12 * currentVertex.x) + (newMatrix.m22 * currentVertex.y) + (newMatrix.m32 * currentVertex.z) + newMatrix.m42;
            new2.z = (newMatrix.m13 * currentVertex.x) + (newMatrix.m23 * currentVertex.y) + (newMatrix.m33 * currentVertex.z) + newMatrix.m43;
            
            float w = (newMatrix.m14 * currentVertex.x) + (newMatrix.m24 * currentVertex.y) + (newMatrix.m34 * currentVertex.z) + newMatrix.m44;
            
            new2.x = new2.x / w;
            new2.y = new2.y / w;
            new2.z = new2.z / w;
            
            
            Vertex *final = [Vertex new];
            
            final.x = ((new.x * point.weight1) + (new2.x * point.weight2)) / (point.weight1 + point.weight2);
            final.y = ((new.y * point.weight1) + (new2.y * point.weight2)) / (point.weight1 + point.weight2);
            final.z = ((new.z * point.weight1) + (new2.z * point.weight2)) / (point.weight1 + point.weight2);
            
            [content appendFormat:@"v %f %f %f\n", final.x, final.y, final.z];
        }
        else {
            [content appendFormat:@"v %f %f %f\n", new.x, new.y, new.z];
        }
        
        indexNode += 1;
    }
    [content appendFormat:@"\n"];
    
    for (NSArray *currentPrimitives in self.primitives) {
        for (id primitive in currentPrimitives) {
            if ([primitive isKindOfClass:[NSString class]]) {
                [content appendFormat:@"\ng %@\n", [currentPrimitives firstObject]];
            }
            else if ([primitive isKindOfClass:[Primitive class]]) {
                Primitive *p = (Primitive *)primitive;
                [content appendFormat:@"f %hu %hu %hu\n", p.x, p.y, p.z];
            }
        }
    }
    
    NSLog(@"\n%@", content);
}

- (void)exportGeometry:(SCNScene *)scene {
    [self loopChildNode:scene.rootNode.childNodes];
    
    for (SCNNode *node in self.nodes) {
        [self exportData:node];
        [self verticesGeometry:node];
        [self primitivesGeometry:node];
    }
    [self generateFile];
}

+ (void)exportGeometry:(SCNScene *)scene {
    Export *export = [Export new];
    [export exportGeometry:scene];
}

@end
