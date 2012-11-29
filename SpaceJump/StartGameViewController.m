//
//  StartGameViewController.m
//  SpaceJump
//
//  Created by Matthew McArthur on 11/3/12.
//  Copyright (c) 2012 Matthew McArthur. All rights reserved.
//

#import "StartGameViewController.h"

@interface StartGameViewController ()

@end

@implementation StartGameViewController

@synthesize proceedToGameAfterTutorial = _proceedToGameAfterTutorial;

#pragma mark - life cycle

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

#pragma mark - view actions
- (IBAction)playButtonPressed
{
    BOOL tutorialHasBeenCompleted = [self hasTutorialBeenCompleted];
    if (tutorialHasBeenCompleted)
    {
        [self performSegueWithIdentifier:@"GoToSelectGameMode" sender:self];
    } else
    {
        self.proceedToGameAfterTutorial = YES;
        [self performSegueWithIdentifier:@"GoToTutorial" sender:self];
    }
}

- (IBAction)tutorialButtonPressed
{
    self.proceedToGameAfterTutorial = NO;
    [self performSegueWithIdentifier:@"GoToTutorial" sender:self];
}

- (IBAction)tutorialCompleted
{
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"tutorial_complete"];
    if (self.proceedToGameAfterTutorial) {
        [self performSegueWithIdentifier:@"ToGameFromTutorial" sender:self];
    }else
    {
        [self performSegueWithIdentifier:@"ToHomeFromTutorial" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController* destVC = [segue destinationViewController];
    if ([destVC isKindOfClass:[StartGameViewController class]]) {
        [(StartGameViewController*)destVC setProceedToGameAfterTutorial:self.proceedToGameAfterTutorial];
    }
}

-(BOOL)hasTutorialBeenCompleted
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"tutorial_complete"];
}

@end
