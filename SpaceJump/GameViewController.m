//
//  GameViewController.m
//  SpaceJump
//
//  Created by Matthew McArthur on 10/22/12.
//  Copyright (c) 2012 Matthew McArthur. All rights reserved.
//

#import "GameViewController.h"
#import "Game.h"

@interface GameViewController ()

@end

@implementation GameViewController

@synthesize mode = _mode;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarHidden = YES;
	CCDirector* director = [CCDirector sharedDirector];
    
    if ([CCDirector setDirectorType:kCCDirectorTypeDisplayLink] == NO)
    {
        [CCDirector setDirectorType:kCCDirectorTypeDefault];
    }
    
    [director setAnimationInterval:1.0/60];
    [director setDisplayFPS:YES];
    [director enableRetinaDisplay:YES];
    
    NSArray* subviews = self.view.subviews;
    for (int i = 0; i < [subviews count]; i++)
    {
        UIView* subview = [subviews objectAtIndex:i];
        if ([subview isKindOfClass:[EAGLView class]])
        {
            subview.hidden = NO;
            [director setOpenGLView:(EAGLView*)subview];
            [director runWithScene:[Game sceneWithMode:self.mode]];
            self.view = director.openGLView;
            break;
        }
    }
    [self dismissModalViewControllerAnimated:YES];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

@end
