//
//  ChildrenExporter.m
//  IKTest
//
//  Created by Remi Robert on 14/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import "ChildrenExporter.h"

@interface MaterialExporter : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *specular;
@property (nonatomic, strong) NSString *diffuse;
@property (nonatomic, strong) NSString *ambiant;
@end

@implementation MaterialExporter
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

@interface ChildrenExporter()
@property (nonatomic, strong) NSMutableArray *childrens;

@property (nonatomic, strong) NSMutableArray *vectrices;
@property (nonatomic, strong) NSMutableArray *primitives;
@property (nonatomic, strong) NSMutableArray *normals;
@property (nonatomic, strong) NSMutableArray *materials;

@property (nonatomic, assign) NSInteger currentIndexParent;
@property (nonatomic, assign) NSInteger currentIndexChild;
@end

@implementation UIColor (String)

- (NSString *)convertToString {
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    return [NSString stringWithFormat:@"%f %f %f", components[0], components[1], components[2]];
}

@end

@implementation ChildrenExporter

#pragma mark -
#pragma mark Struct handler

static MaterialExporter *newMaterial(SCNMaterial *mat) {
    MaterialExporter *newMat = [MaterialExporter new];
    newMat.ambiant = [((UIColor *)mat.ambient.contents) convertToString];
    newMat.diffuse = [((UIColor *)mat.diffuse.contents) convertToString];
    newMat.specular = [((UIColor *)mat.specular.contents) convertToString];
    newMat.name = mat.name;
    return newMat;
}

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

#pragma mark -
#pragma mark Childerns

- (NSString *)nameChildren {
    if (self.currentIndexParent < self.childrens.count) {
        NSArray *currentChildrens = [self.childrens objectAtIndex:self.currentIndexParent];
        if (currentChildrens) {
            return [currentChildrens objectAtIndex:self.currentIndexChild];
        }
    }
    return nil;
}

#pragma mark Parse childrens node

- (NSInteger)indexForParent:(NSString *)parent {
    NSInteger index = 0;
    for (NSArray *currentChildrens in self.childrens) {
        for (SCNNode *currentNode  in currentChildrens) {
            if ([currentNode.name isEqualToString:parent]) {
                return index;
            }
        }
        index += 1;
    }
    return NSNotFound;
}

- (void)loopChildNode:(NSArray *)children {
    for (SCNNode *node in children) {
        NSInteger index = [self indexForParent:node.parentNode.name];
        if (index != NSNotFound) {
            [[self.childrens objectAtIndex:index] addObject:node];
        }
        
        if (node.childNodes) {
            [self loopChildNode:node.childNodes];
        }
    }
}

- (void)parseChildrens:(SCNScene *)scene {
    self.childrens = [[NSMutableArray alloc] init];

    for (SCNNode *currentChildNode in scene.rootNode.childNodes) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:currentChildNode];
        [self.childrens addObject:array];
    }
    
    for (SCNNode *currentChildNode in scene.rootNode.childNodes) {
        [self loopChildNode:currentChildNode.childNodes];
    }
}

#pragma mark -
#pragma mark Geometry Source handler

#pragma mark Normal

- (void)parseNormalSource:(SCNGeometrySource *)vertexSource {
    NSInteger stride = vertexSource.dataStride;
    NSInteger offset = vertexSource.dataOffset;
    
    NSInteger componentsPerVector = vertexSource.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * vertexSource.bytesPerComponent;
    NSInteger vectorCount = vertexSource.vectorCount;
    
    for (NSInteger i=0; i<vectorCount; i++) {
        float vectorData[componentsPerVector];
        
        NSRange byteRange = NSMakeRange(i*stride + offset, bytesPerVector);
        
        [vertexSource.data getBytes:&vectorData range:byteRange];
        
        if (!self.normals) {
            self.normals = [[NSMutableArray alloc] init];
        }
        [self.normals addObject:newVertex(vectorData[0], vectorData[1], vectorData[2])];
    }
}

- (void)normalGeometry:(SCNNode *)node {
    if (!node.geometry) {
        return;
    }
    NSArray *vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticNormal];
    
    if (!vertexSources) {
        return;
    }
    for (SCNGeometrySource *currentSource in vertexSources) {
        [self parseNormalSource:currentSource];
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

        if (!self.vectrices) {
            self.vectrices = [[NSMutableArray alloc] init];
        }
        [self.vectrices addObject:newVertex(x, y, z)];
    }
}

- (void)verticesGeometry:(SCNNode *)node {
    if (!node.geometry) {
        return;
    }
    NSArray *vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    
    if (!vertexSources) {
        return;
    }
    for (SCNGeometrySource *currentSource in vertexSources) {
        [self parseVertexSource:currentSource];
    }
}

#pragma mark Primitives

- (void)parsePrimitivesSource:(SCNGeometryElement *)primitiveElement {
    NSMutableArray *currentContent = [[NSMutableArray alloc] init];
    
    [currentContent addObject:[self nameChildren]];
    [currentContent addObject:[self.materials objectAtIndex:self.currentIndexChild]];
    
    for (int index = 0; index < primitiveElement.data.length; index += primitiveElement.bytesPerIndex * 3) {
        ushort buff[3] = {0, 0, 0};
        
        [primitiveElement.data getBytes:&buff range:NSMakeRange(index, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[1] range:NSMakeRange(index + primitiveElement.bytesPerIndex, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[2] range:NSMakeRange(index + primitiveElement.bytesPerIndex * 2, primitiveElement.bytesPerIndex)];
        
        [currentContent addObject:newPrimitive(buff[0] + 1, buff[1] + 1, buff[2] + 1)];

        SCNNode *currentChildren = [[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild];
        
        
        for (int index = 0; index < 3; index++) {
            Vertex *currentVertex = [self.vectrices objectAtIndex:buff[index]];
            currentVertex.x = (currentChildren.presentationNode.worldTransform.m11 * currentVertex.x) + (currentChildren.presentationNode.worldTransform.m12 * currentVertex.x) + (currentChildren.presentationNode.worldTransform.m13 * currentVertex.x) + currentChildren.presentationNode.worldTransform.m14;
            currentVertex.y = (currentChildren.presentationNode.worldTransform.m11 * currentVertex.y) + (currentChildren.presentationNode.worldTransform.m12 * currentVertex.y) + (currentChildren.presentationNode.worldTransform.m13 * currentVertex.y) + currentChildren.presentationNode.worldTransform.m24;
            currentVertex.z = (currentChildren.presentationNode.worldTransform.m11 * currentVertex.z) + (currentChildren.presentationNode.worldTransform.m12 * currentVertex.z) + (currentChildren.presentationNode.worldTransform.m13 * currentVertex.z) + currentChildren.presentationNode.worldTransform.m34;
        }
    }
    if (!self.primitives) {
        self.primitives = [[NSMutableArray alloc] init];
    }
    [self.primitives addObject:currentContent];
}

- (void)primitivesGeometry:(SCNNode *)node {
    if (!node.geometry) {
        return;
    }
    self.currentIndexChild = 0;
    for (int indexElement = 0; indexElement < node.geometry.geometryElementCount; indexElement++) {
        SCNGeometryElement *currentElement = [node.geometry geometryElementAtIndex:indexElement];
        if (currentElement) {
            [self parsePrimitivesSource:currentElement];
        }
        self.currentIndexChild += 1;
    }
}

#pragma mark Materials

- (void)materialsGeometry:(SCNNode *)node {
    if (!node.geometry) {
        return;
    }
    for (SCNMaterial *currentMaterial in node.geometry.materials) {
        if (!self.materials) {
            self.materials = [[NSMutableArray alloc] init];
        }
        [self.materials addObject:newMaterial(currentMaterial)];
        NSLog(@"name : %@ -> %@", currentMaterial.name, (UIColor *)currentMaterial.diffuse.contents);
    }
}

#pragma mark -
#pragma mark Exporteur

- (void)generateFileMaterial {
    NSMutableString *content = [[NSMutableString alloc] init];

    for (MaterialExporter *currentMaterial in self.materials) {
        [content appendFormat:@"\nnewmtl %@\n", currentMaterial.name];
        [content appendFormat:@"Ka %@\n", currentMaterial.ambiant];
        [content appendFormat:@"Ks %@\n", currentMaterial.specular];
        [content appendFormat:@"Kd %@\n", currentMaterial.diffuse];
        [content appendFormat:@"illum 2\n"];
    }
    NSLog(@"\n\n%@", content);
}

- (void)generateFileGeometry {
    NSMutableString *content = [[NSMutableString alloc] init];
    
    for (Vertex *currentVertex in self.vectrices) {
        [content appendFormat:@"v %f %f %f\n", currentVertex.x, currentVertex.y, currentVertex.z];
    }
    [content appendFormat:@"\n"];

    for (Vertex *currentNormal in self.normals) {
        [content appendFormat:@"vn %f %f %f\n", currentNormal.x, currentNormal.y, currentNormal.z];
    }
    [content appendFormat:@"\n"];

    for (NSArray *currentPrimitives in self.primitives) {
        
        for (int indexPrimitive = 0; indexPrimitive < currentPrimitives.count; indexPrimitive++) {
            id currentPrimitive = [currentPrimitives objectAtIndex:indexPrimitive];
            
            if ([currentPrimitive isKindOfClass:[SCNNode class]]) {
                [content appendFormat:@"\ng %@\n", ((SCNNode *)[currentPrimitives firstObject]).name];
            }
            else if ([currentPrimitive isKindOfClass:[MaterialExporter class]]) {
                [content appendFormat:@"usemtl %@\n", ((MaterialExporter *)currentPrimitive).name];
            }
            else {
                [content appendFormat:@"f %u %u %u\n", ((Primitive *)currentPrimitive).x, ((Primitive *)currentPrimitive).y, ((Primitive *)currentPrimitive).z];
            }
        }
    }
    NSLog(@"\n%@", content);
}

- (void)childrenGeometry {
    self.currentIndexParent = 0;
    for (NSArray *currenChildrens in self.childrens) {
        for (SCNNode *currentNode in currenChildrens) {
            if (currentNode && currentNode.geometry) {
                [self materialsGeometry:currentNode];
                [self verticesGeometry:currentNode];
                [self primitivesGeometry:currentNode];
                [self normalGeometry:currentNode];
            }
        }
        self.currentIndexParent += 1;
    }
}

+ (void)exportFromScene:(SCNScene *)scene {
    ChildrenExporter *exporteur = [[ChildrenExporter alloc] init];
    [exporteur parseChildrens:scene];
    if (!exporteur.childrens) {
        return;
    }
    NSLog(@"%@", exporteur.childrens);
    [exporteur childrenGeometry];
    [exporteur generateFileGeometry];
    [exporteur generateFileMaterial];
}

@end
