//
//  ViewController.m
//  OpenGLEffects
//
//  Created by Lion User on 26.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "GrayscaleFilter.h"
#import "OpenGLBlurView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    GrayscaleFilter* gs = [[GrayscaleFilter alloc]init];
    UIImageView* imagView = [[self.view subviews]objectAtIndex:2];
    UIImage* img = [gs filter:imagView.image];
    imagView.image = img;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)click:(id)sender {
    UIView* view = [[self.view subviews]objectAtIndex:0];
    
    OpenGLBlurView* openglBlurView = [[self.view subviews]objectAtIndex:1];
    openglBlurView.frame = CGRectOffset(openglBlurView.frame, 20, 20);
    //openglBlurView.opaque = YES;
    [openglBlurView renderLayer:view.layer];

}
@end
