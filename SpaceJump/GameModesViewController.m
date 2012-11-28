//
//  GameModesViewController.m
//  SpaceJump
//
//  Created by Matthew McArthur on 11/15/12.
//  Copyright (c) 2012 Matthew McArthur. All rights reserved.
//

#import "GameModesViewController.h"

@interface GameModesViewController ()

@property (nonatomic,strong) NSString* mode;

@end

@implementation GameModesViewController

@synthesize mode = _mode;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarHidden = YES;
	// Do any additional setup after loading the view.
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (IBAction)timedModePressed:(id)sender
{
    self.mode = @"TimedMode";
    [self performSegueWithIdentifier:@"PlayGame" sender:self];
}

- (IBAction)easyModePressed:(id)sender
{
    self.mode = @"EasyMode";
    [self performSegueWithIdentifier:@"PlayGame" sender:self];
}

- (IBAction)hardModePressed:(id)sender
{
    self.mode = @"HardMode";
    [self performSegueWithIdentifier:@"PlayGame" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[segue destinationViewController] setMode:self.mode];
}

@end
