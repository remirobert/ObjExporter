//
//  ChildrenExporter.m
//  IKTest
//
//  Created by Remi Robert on 14/04/15.
//  Copyright (c) 2015 Itsuki Ichikawa. All rights reserved.
//

#import "ChildrenExporter.h"

@interface PrimitiveExporter : NSObject
@property (nonatomic, strong) SCNNode *node;
@property (nonatomic, strong) NSMutableArray *primitives;
@end

@implementation PrimitiveExporter
@end

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
@property (nonatomic, strong) NSMutableArray *vectricesCalculated;
@property (nonatomic, strong) NSMutableArray *primitives;
@property (nonatomic, strong) NSMutableArray *normals;
@property (nonatomic, strong) NSMutableArray *materials;

@property (nonatomic, strong) NSMutableArray *bones;

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

- (void)displayMatrix:(SCNMatrix4)maxtrix {
    NSLog(@"matrix-------");
    printf("{%f %f %f %f}\n", maxtrix.m11, maxtrix.m21, maxtrix.m31, maxtrix.m41);
    printf("{%f %f %f %f}\n", maxtrix.m12, maxtrix.m22, maxtrix.m32, maxtrix.m42);
    printf("{%f %f %f %f}\n", maxtrix.m13, maxtrix.m23, maxtrix.m33, maxtrix.m43);
    printf("{%f %f %f %f}\n", maxtrix.m14, maxtrix.m24, maxtrix.m34, maxtrix.m44);
    NSLog(@"-------------");
}

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

- (SCNNode *)nodeFromName:(NSString *)name {
    for (NSArray *currentChildrens in self.childrens) {
        for (SCNNode *node in currentChildrens) {
            if ([node.name isEqualToString:name]) {
                return node;
            }
        }
    }
    return nil;
}

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

#pragma mark Bones

- (void)parseBones {
    self.bones = [NSMutableArray array];
    
    for (NSArray *currentChildrens in self.childrens) {
        NSMutableArray *bones = [NSMutableArray array];
        
        for (SCNNode *child in currentChildrens) {
            NSLog(@"----------> %@", child.name);
            if (child.skinner && child.skinner.skeleton) {
                
                for (SCNNode *c in child.skinner.bones) {
                    NSLog(@"c : %@ [%@]", c.name, c.childNodes);
                }
                
                [bones addObject:child];
            }
        }
        if (bones.count > 0) {
            [self.bones addObject:bones];
        }
    }
}

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
    NSArray *vertexSources;
    vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticNormal];

    if (!vertexSources) {
        return;
    }
    for (SCNGeometrySource *currentSource in vertexSources) {
        [self parseNormalSource:currentSource];
    }
}

#pragma mark Vectrices

- (void)parseVertexSource:(SCNGeometrySource *)vertexSource {
    if (!self.vectrices) {
        self.vectrices = [[NSMutableArray alloc] init];
    }

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
    if (!node.geometry) {
        return;
    }
    NSArray *vertexSources;
    vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    
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

    //SCNNode *currentChildren = ((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild]).presentationNode;
//    SCNNode *currentChildren = [self nodeFromName:@"Armature"];//((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent]
    NSLog(@"%ld %ld -> [%ld] ===============[%@]================", (long)self.currentIndexParent, (long)self.currentIndexChild, (long)primitiveElement.primitiveCount, ((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild]).name);
//    NSLog(@"scale : %f %f %f", currentChildren.presentationNode.scale.x, currentChildren.presentationNode.scale.y, currentChildren.presentationNode.scale.z);
//    NSLog(@"position : %f %f %f", currentChildren.presentationNode.position.x, currentChildren.presentationNode.position.y, currentChildren.presentationNode.position.z);
//    [self displayMatrix:currentChildren.presentationNode.transform];
//    [self displayMatrix:currentChildren.presentationNode.worldTransform];
    NSLog(@"================================");
    
    SCNNode *currentChildren2 = ((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild]);

    
    NSLog(@"@@@@@@@@@@@ %@ @@@@@@@@@@@@", currentChildren2.name);
    [self displayMatrix:currentChildren2.transform];
    [self displayMatrix:currentChildren2.worldTransform];
    NSLog(@"@@@@@@@@@@@@@@@@@@@@@@@@@@");
    
    for (int index = 0; index < primitiveElement.data.length; index += primitiveElement.bytesPerIndex * 3) {
        ushort buff[3] = {0, 0, 0};
        
        [primitiveElement.data getBytes:&buff range:NSMakeRange(index, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[1] range:NSMakeRange(index + primitiveElement.bytesPerIndex, primitiveElement.bytesPerIndex)];
        [primitiveElement.data getBytes:&buff[2] range:NSMakeRange(index + primitiveElement.bytesPerIndex * 2, primitiveElement.bytesPerIndex)];
        
        [currentContent addObject:newPrimitive(buff[0] + 1, buff[1] + 1, buff[2] + 1)];
//        SCNNode *currentChildren = ((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild]).presentationNode;

        
//        if (currentChildren.skinner) {
//            currentChildren = currentChildren.skinner.skeleton.presentationNode;
//        }

        
        
//        NSLog(@"name : %@ [%f %f %f] [%f %f %f] [%f %f %f]", currentChildren.name, currentChildren.worldTransform.m11, currentChildren.worldTransform.m12, currentChildren.worldTransform.m13, currentChildren.worldTransform.m21, currentChildren.worldTransform.m22, currentChildren.worldTransform.m23, currentChildren.worldTransform.m31, currentChildren.worldTransform.m32, currentChildren.worldTransform.m33);
        
//        if ([currentChildren.name isEqualToString:@"BoneA"] || [currentChildren.name isEqualToString:@"BoneB"] || [currentChildren.name isEqualToString:@"BoneC"]) {
            for (int index = 0; index < 3; index++) {
                Vertex *currentVertex = [self.vectrices objectAtIndex:buff[index]];
                
                
                
                //SCNNode *currentChildren = [self nodeFromName:@"Armature"];
                SCNNode *currentChildren = ((SCNNode *)[[self.childrens objectAtIndex:self.currentIndexParent] objectAtIndex:self.currentIndexChild]);

                Vertex *new = [Vertex new];
                new.x = currentVertex.x;
                new.y = currentVertex.y;
                new.z = currentVertex.z;


        
                //GOOD calcul
                
                SCNMatrix4 newMatrix = currentChildren.worldTransform;
                
                new.x = (newMatrix.m11 * currentVertex.x) + (newMatrix.m21 * currentVertex.y) + (newMatrix.m31 * currentVertex.z) + newMatrix.m41;
                new.y = (newMatrix.m12 * currentVertex.x) + (newMatrix.m22 * currentVertex.y) + (newMatrix.m32 * currentVertex.z) + newMatrix.m42;
                new.z = (newMatrix.m13 * currentVertex.x) + (newMatrix.m23 * currentVertex.y) + (newMatrix.m33 * currentVertex.z) + newMatrix.m43;
                float w = (newMatrix.m14 * currentVertex.x) + (newMatrix.m24 * currentVertex.y) + (newMatrix.m34 * currentVertex.z) + newMatrix.m44;

                
                new.x = new.x / w;
                new.y = new.y / w;
                new.z = new.z / w;
                
                
                NSLog(@"------------------");
                //[self displayMatrix:newMatrix];
                NSLog(@"before [%f %f %f]", currentVertex.x, currentVertex.y, currentVertex.z);
                NSLog(@"after  [%f %f %f]", new.x, new.y, new.z);
                
                [self.vectricesCalculated addObject:new];
//                [self.vectrices removeObjectAtIndex:buff[index]];
//                [self.vectrices insertObject:new atIndex:buff[index]];

            }
        //}
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
    NSLog(@"%@ : %d",node.name, (int)node.geometry.geometryElementCount);
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
    NSMutableString *contentUpdate = [[NSMutableString alloc] init];
    
    for (Vertex *currentVertex in self.vectricesCalculated) {
        [content appendFormat:@"v %f %f %f\n", currentVertex.x, currentVertex.y, currentVertex.z];
    }
    [content appendFormat:@"\n"];

//    uncomment this.
//    for (Vertex *currentNormal in self.normals) {
//        [content appendFormat:@"vn %f %f %f\n", currentNormal.x, currentNormal.y, currentNormal.z];
//    }
//    [content appendFormat:@"\n"];
    
    NSInteger currentIndexVertex = 1;
    SCNNode *currentChildren;
    NSInteger currentChildrenIndex = 0;
    
    
    for (NSArray *currentPrimitives in self.primitives) {
        
        for (int indexPrimitive = 0; indexPrimitive < currentPrimitives.count; indexPrimitive++) {
            id currentPrimitive = [currentPrimitives objectAtIndex:indexPrimitive];
            
            if ([currentPrimitive isKindOfClass:[SCNNode class]]) {
                currentChildren = [[self.childrens objectAtIndex:1] objectAtIndex:currentChildrenIndex];//((SCNNode *)[currentPrimitives firstObject]);
                NSLog(@"@                   name : [%@]", currentChildren.name);
                currentChildrenIndex += 1;
                [content appendFormat:@"\ng %@\n", ((SCNNode *)[currentPrimitives firstObject]).name];
                
                //currentChildren = ((SCNNode *)[currentPrimitives firstObject]);
                
            }
            else if ([currentPrimitive isKindOfClass:[MaterialExporter class]]) {
                [content appendFormat:@"usemtl %@\n", ((MaterialExporter *)currentPrimitive).name];
            }
            else {
//                for (int i = 0; i < 3; i++) {
//                    Vertex *currentVertex = [self.vectricesCalculated objectAtIndex:currentIndexVertex - 1 + i];
//                    Vertex *new = [Vertex new];
//                    
//                    SCNMatrix4 newMatrix = currentChildren.transform;
//
//
//                    new.x = (newMatrix.m11 * currentVertex.x) + (newMatrix.m21 * currentVertex.y) + (newMatrix.m31 * currentVertex.z) + newMatrix.m41;
//                    new.y = (newMatrix.m12 * currentVertex.x) + (newMatrix.m22 * currentVertex.y) + (newMatrix.m32 * currentVertex.z) + newMatrix.m42;
//                    new.z = (newMatrix.m13 * currentVertex.x) + (newMatrix.m23 * currentVertex.y) + (newMatrix.m33 * currentVertex.z) + newMatrix.m43;
//
//                    float w = (newMatrix.m14 * currentVertex.x) + (newMatrix.m24 * currentVertex.y) + (newMatrix.m34 * currentVertex.z) + newMatrix.m44;
//
//                    
////                    new.x = (currentChildren.worldTransform.m11 * currentVertex.x) + (currentChildren.worldTransform.m21 * currentVertex.y) + (currentChildren.worldTransform.m31 * currentVertex.z) + currentChildren.worldTransform.m41;
////                    new.y = (currentChildren.worldTransform.m12 * currentVertex.x) + (currentChildren.worldTransform.m22 * currentVertex.y) + (currentChildren.worldTransform.m32 * currentVertex.z) + currentChildren.worldTransform.m42;
////                    new.z = (currentChildren.worldTransform.m13 * currentVertex.x) + (currentChildren.worldTransform.m23 * currentVertex.y) + (currentChildren.worldTransform.m33 * currentVertex.z) + currentChildren.worldTransform.m43;
//                    
//                    
//                    
////                    new.x += (currentChildren.transform.m11 * currentVertex.x) + (currentChildren.transform.m21 * currentVertex.y) + (currentChildren.transform.m31 * currentVertex.z) + currentChildren.transform.m41;
////                    new.y += (currentChildren.transform.m12 * currentVertex.x) + (currentChildren.transform.m22 * currentVertex.y) + (currentChildren.transform.m32 * currentVertex.z) + currentChildren.transform.m42;
////                    new.z += (currentChildren.transform.m13 * currentVertex.x) + (currentChildren.transform.m23 * currentVertex.y) + (currentChildren.transform.m33 * currentVertex.z) + currentChildren.transform.m43;
//                    
////                    float w = (currentChildren.worldTransform.m14 * currentVertex.x) + (currentChildren.worldTransform.m24 * currentVertex.y) + (currentChildren.worldTransform.m34 * currentVertex.z) + currentChildren.worldTransform.m44;
//                    
////                    float w2 = (currentChildren.transform.m14 * currentVertex.x) + (currentChildren.transform.m24 * currentVertex.y) + (currentChildren.transform.m34 * currentVertex.z) + currentChildren.transform.m44;
//
//                    
//                    new.x = new.x / w;
//                    new.y = new.y / w;
//                    new.z = new.z / w;
//                    [contentUpdate appendFormat:@"v %f %f %f\n", new.x, new.y, new.z];
//                }
                
                
                [content appendFormat:@"f %ld %ld %ld\n", (long)currentIndexVertex, currentIndexVertex + 1, currentIndexVertex + 2];
                currentIndexVertex += 3;
            }
//            else {
//                [content appendFormat:@"f %u %u %u\n", indexPrimitive + 1, indexPrimitive + 2, indexPrimitive + 3];
//                indexPrimitive += 2;
//                //[content appendFormat:@"f %u %u %u\n", ((Primitive *)currentPrimitive).x, ((Primitive *)currentPrimitive).y, ((Primitive *)currentPrimitive).z];
//            }
        }
    }
    //[contentUpdate appendFormat:[NSString stringWithFormat:@"%@", content]];
    NSLog(@"\n%@", content);
}

- (void)childrenGeometry {
    self.vectricesCalculated = [NSMutableArray array];
    self.currentIndexParent = 0;
    for (NSArray *currenChildrens in self.childrens) {
        for (SCNNode *currentNode in currenChildrens) {
            if (currentNode) {
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
    ChildrenExporter *exporteur = [ChildrenExporter new];
    [exporteur parseChildrens:scene];

    [exporteur parseBones];
    
    
    NSLog(@"bones : %@", exporteur.bones);
    
    
    if (!exporteur.childrens) {
        return;
    }
    for (NSArray *currentNodes in exporteur.childrens) {
        NSLog(@"[");
        for (SCNNode *node in currentNodes) {
            NSLog(@"    [%@]->{%@}", node, node.parentNode.name);
        }
        NSLog(@"]");
    }
    //NSLog(@"%@", exporteur.childrens);
    [exporteur childrenGeometry];
    
    
    NSLog(@"number file vectex : %d", exporteur.vectrices.count);
    NSLog(@"number file vectex calculmated  : %d", exporteur.vectricesCalculated.count);
    [exporteur generateFileGeometry];
    //[exporteur generateFileMaterial];
}

@end
