//
//  GameViewController.m
//  IKTest
//
//  Created by 市川樹 on 2014/12/18.
//  Copyright (c) 2014年 Itsuki Ichikawa. All rights reserved.
//

#import "GameViewController.h"
#import "Exporter.h"
#import "ChildrenExporter.h"
#import "Export.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface GameViewController()
@property (nonatomic, strong) SCNScene *sceneVar;
@property (strong, nonatomic) IBOutlet SCNView *scnView;
@end

@implementation GameViewController

- (void)checkTransform {
    for (SCNNode *node in scene.rootNode.childNodes) {
        if (node.geometry) {
            NSLog(@"");
//            NSLog(@"-> [%f %f %f] [%f %f %f] [%f %f %f]", node.worldTransform.m11, node.worldTransform.m12, node.worldTransform.m13, node.worldTransform.m21, node.worldTransform.m22, node.worldTransform.m23, node.worldTransform.m31, node.worldTransform.m32, node.worldTransform.m33);
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCNMatrix4 identity = SCNMatrix4Identity;

    [self displayMatrix:identity];
    
    scene = [SCNScene sceneNamed:@"TestArm.dae"];//[SCNScene sceneNamed:@"stone.dae"];
    
//    SCNScene *sc = [SCNScene sceneNamed:@"tigTest2.dae"];
//
//    SCNNode *rootSelected = [sc.rootNode childNodeWithName:@"Armature" recursively:true];
//    rootSelected.position = SCNVector3Make(0, 0, 0);
//    [scene.rootNode addChildNode:rootSelected];
    
    
//    SCNScene *sc2 = [SCNScene sceneNamed:@"TestArm2.dae"];
//    
//    SCNNode *rootSelected2 = [sc2.rootNode childNodeWithName:@"Arm2" recursively:true];
//    rootSelected2.position = SCNVector3Make(0, -10, 0);
//    [scene.rootNode addChildNode:rootSelected2];

    
    //[scene.rootNode addChildNode:[SCNNode ]]
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 8);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 0, -1);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor lightGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    //　部位ごとのNodeの作成
    //　モデル全体
    arm = [scene.rootNode childNodeWithName:@"Arm" recursively:YES];
    NSLog(@"arm : %@", arm);
    //　モデルの根っこ
    arm_root = [arm childNodeWithName:@"RootBone" recursively:YES];
    //　モデルの末端
    arm_end = [arm childNodeWithName:@"BoneC" recursively:YES];
    
    //　モデルの各ノード
    arm_A = [arm childNodeWithName:@"BoneA" recursively:YES];
    arm_B = [arm childNodeWithName:@"BoneB" recursively:YES];
    
    //　SCNIKConstraint:IKの用意
    ik = [SCNIKConstraint inverseKinematicsConstraintWithChainRootNode:arm_root];
    //　モデルの末端に拘束条件として先ほど用意したIKを設定する

        arm_end.constraints = @[ik];
    ik.influenceFactor = 1.0;
    
    //　試しに動かしてみる
    [SCNTransaction begin];
    //　目標位置をSCNIKConstraintに与える
    //ik.targetPosition = [scene.rootNode convertPosition:SCNVector3Make(0,-1,0) toNode:nil];
    
    [SCNTransaction commit];
    
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    

    
    // set the scene to the view
    scnView.scene = scene;
    
    // show statistics such as fps and timing information
    scnView.showsStatistics = YES;
    
    // configure the view
    scnView.backgroundColor = [UIColor lightGrayColor];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    button.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(generateOBJ) forControlEvents:UIControlEventTouchUpInside];

    //[arm setTransform:CATransform3DRotate(arm.transform, DEGREES_TO_RADIANS(45), 0, 0, 0)];
    
    arm.eulerAngles = SCNVector3Make(DEGREES_TO_RADIANS(20), DEGREES_TO_RADIANS(20), DEGREES_TO_RADIANS(20));
    //[arm setRotation:SCNVector4Make(0, DEGREES_TO_RADIANS(45), 0, 1)];

    
//    arm.rotation = SCNVector4Make(0, 0, 0.3, 1);
    
    //[export export:scene];
 }

- (void)generateOBJ {
    [Export exportGeometry:scene];

}

- (void)displayMatrix:(SCNMatrix4)maxtrix {
    NSLog(@"matrix-------");
    NSLog(@"{%f %f %f %f}", maxtrix.m11, maxtrix.m12, maxtrix.m13, maxtrix.m14);
    NSLog(@"{%f %f %f %f}", maxtrix.m21, maxtrix.m22, maxtrix.m23, maxtrix.m24);
    NSLog(@"{%f %f %f %f}", maxtrix.m31, maxtrix.m32, maxtrix.m33, maxtrix.m34);
    NSLog(@"{%f %f %f %f}", maxtrix.m41, maxtrix.m42, maxtrix.m43, maxtrix.m44);
    NSLog(@"-------------");
}

- (void)displayTransformation:(NSArray *)nodes {
    
    for (SCNNode *node in nodes) {
        if (node.skinner) {
            NSLog(@"[%@]skeleton : %@ %@", node.name, node.skinner.skeleton.presentationNode, node.skinner.bones);
        }
        NSLog(@"---------> [%@]", node.name);
        [self displayMatrix:node.worldTransform];
//        NSLog(@"-> [%@] [%f %f %f] [%f %f %f] [%f %f %f] [%f %f %f]", node.name, node.worldTransform.m11, node.worldTransform.m12, node.worldTransform.m13, node.worldTransform.m21, node.worldTransform.m22, node.worldTransform.m23, node.worldTransform.m31, node.worldTransform.m32, node.presentationNode.worldTransform.m33, node.presentationNode.worldTransform.m41, node.presentationNode.worldTransform.m42, node.presentationNode.worldTransform.m43);
        //NSLog(@"%f %f %f", node.presentationNode.scale.x, node.presentationNode.scale.y, node.presentationNode.scale.z);
        
        if (node.childNodes.count > 0) {
            [self displayTransformation:node.childNodes];
        }
    }
    
    
    ///if (node.name) {
//        for (SCNNode *node in cnode.childNodes) {
////            NSLog(@"[%@]: current rotation : %f %f %f", node.name, node.presentationNode.eulerAngles.x, node.presentationNode.eulerAngles.y,node.presentationNode.eulerAngles.z);
//            
//            if (node.skinner) {
//                NSLog(@"%f %f %f", node.scale.x, node.scale.y, node.scale.z);
//            }
//            
//            for (SCNNode *child in node.childNodes) {
//                [self displayTransformation:child];
//            }
//            
////            NSLog(@"[%@]: current rotation : %f %f %f %f %f %f %f %f %f %f %f %f", node.name, node.presentationNode.worldTransform.m11, node.presentationNode.worldTransform.m12, node.presentationNode.worldTransform.m13, node.presentationNode.worldTransform.m14, node.presentationNode.worldTransform.m21, node.presentationNode.worldTransform.m22, node.presentationNode.worldTransform.m23, node.presentationNode.worldTransform.m24, node.presentationNode.worldTransform.m31, node.presentationNode.worldTransform.m32, node.presentationNode.worldTransform.m33, node.presentationNode.worldTransform.m34);
//            //[self displayTransformation:cnode];
//        }
//    }
}

- (void)loop:(SCNNode *)node {
    NSLog(@"%@ : [%f %f %f %f][%f %f %f %f][%f %f %f %f][%f %f %f %f]", node.name, node.transform.m11, node.transform.m12, node.transform.m13, node.transform.m14, node.transform.m21, node.transform.m22, node.transform.m23, node.transform.m24, node.transform.m31, node.transform.m32, node.transform.m33, node.transform.m34, node.transform.m41, node.transform.m42, node.transform.m43, node.transform.m44);

    for (SCNNode *n in node.childNodes) {
        [self loop:n];
    }
}

//　画面内をタッチしてIKの目標地点を動かす
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    //　タッチイベントの取得
    UITouch *touch = [touches anyObject];
    //　タッチの位置
    CGPoint touchPoint =[touch locationInView:self.view];
    //　画面の大きさ
    float screenW = self.view.frame.size.width;
    float screenH = self.view.frame.size.height;
    //　移動先の座標の設定
    float movetoX = ((touchPoint.x - screenW/2.0)*8.0)/screenW;
    float movetoY = ((touchPoint.y - screenH/2.0)*8.0)/screenH*-1.0;
    //　IKの目標地点を設定（これで動く）

    [arm setRotation:SCNVector4Make(0, DEGREES_TO_RADIANS(45), 0, 1)];
    [scene.rootNode setPosition:SCNVector3Make(movetoX, movetoY, 0)];

    
    NSLog(@"-------------------------------------");
    [self loop:scene.rootNode];
//    NSLog(@"-------------------------------------");
//    NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f]", arm.name, arm.worldTransform.m11, arm.worldTransform.m12, arm.worldTransform.m13, arm.worldTransform.m21, arm.worldTransform.m22, arm.worldTransform.m23, arm.worldTransform.m31, arm.worldTransform.m32, arm.worldTransform.m33);
//    NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f]", arm_root.name, arm_root.worldTransform.m11, arm_root.worldTransform.m12, arm_root.worldTransform.m13, arm_root.worldTransform.m21, arm_root.worldTransform.m22, arm_root.worldTransform.m23, arm_root.worldTransform.m31, arm_root.worldTransform.m32, arm_root.worldTransform.m33);
//    NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f]", arm_A.name, arm_A.worldTransform.m11, arm_A.worldTransform.m12, arm_A.worldTransform.m13, arm_A.worldTransform.m21, arm_A.worldTransform.m22, arm_A.worldTransform.m23, arm_A.worldTransform.m31, arm_A.worldTransform.m32, arm_A.worldTransform.m33);
//    NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f]", arm_B.name, arm_B.worldTransform.m11, arm_B.worldTransform.m12, arm_B.worldTransform.m13, arm_B.worldTransform.m21, arm_B.worldTransform.m22, arm_B.worldTransform.m23, arm_B.worldTransform.m31, arm_B.worldTransform.m32, arm_B.worldTransform.m33);
//    NSLog(@"%@ : [%f %f %f][%f %f %f][%f %f %f]", arm_end.name, arm_end.worldTransform.m11, arm_end.worldTransform.m12, arm_end.worldTransform.m13, arm_end.worldTransform.m21, arm_end.worldTransform.m22, arm_end.worldTransform.m23, arm_end.worldTransform.m31, arm_end.worldTransform.m32, arm_end.worldTransform.m33);


    
    //ik.targetPosition = [scene.rootNode convertPosition:SCNVector3Make(movetoX,movetoY,0) toNode:nil];
    //　各ノードの角度を取ってみる
//    NSLog(@"------------------------------------------");
//    
//    
//    [self displayTransformation:scene.rootNode.childNodes];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
