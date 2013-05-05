//
//  WorldViewController.m
//  App Stream
//
//  Created by de Lange Paul on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "WorldViewController.h"

#import "SceneGraph.h"

#import "Background.h"

@interface WorldViewController() <GLKViewDelegate> {
    SceneGraph* _graph;
    
    CGFloat _scale;
    CGPoint _offset;
}

@end

@implementation WorldViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _graph = [SceneGraph new];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GLKView* view = (GLKView*)self.view;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
    
    //Configure self
    self.preferredFramesPerSecond = 60.f;
    self.delegate = _graph;
    
    //Configure OpenGL
    [EAGLContext setCurrentContext: context];
    
    //Configure View
    view.context = context;
    view.contentScaleFactor = [UIScreen mainScreen].scale;
    view.delegate = self;
    
    Background* background = [Background new];
    [_graph addNode: background];
    
    GLint max;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &max);
    
    NSLog(@"Maximum texture size is %d", max);
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                          action: @selector(panPushed:)];
    [view addGestureRecognizer: pan];
    
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget: self
                                                                                action: @selector(pinchPushed:)];
    [view addGestureRecognizer: pinch];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    //Tear down OpenGL
    [EAGLContext setCurrentContext: nil];
    
    //Tear down self
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}
/*
- (void) update 
{
    
}*/

- (IBAction) panPushed:(UIPanGestureRecognizer*)sender {
    
    CGPoint translation = [sender translationInView: sender.view];
    _graph.offset = translation;
}

- (IBAction) pinchPushed: (UIPinchGestureRecognizer*)sender {
    _graph.scale = sender.scale;
}

#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect 
{
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT); 
    
    for(Node* node in [_graph nodesIntersectingRect: rect]) {
#if DEBUG
        if( [node respondsToSelector: @selector(debugRender)])
            [node debugRender];
#endif
        [node render];
    }
}

@end
