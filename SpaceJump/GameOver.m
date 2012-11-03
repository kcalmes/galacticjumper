#import "GameOver.h"
#import "CCMain.h"
#import "Game.h"
#import "GameViewController.h"

@interface GameOver (Private)
- (void)playAgainAction:(id)sender;
- (void)exitGameAction:(id)sender;
@end


@implementation GameOver

+ (CCScene *)gameOverSceneWithScore:(int)lastScore
{
    CCScene *game = [CCScene node];
    
    GameOver *layer = [[[GameOver alloc] initWithScore:lastScore] autorelease];
    [game addChild:layer];
    
    return game;
}

- (id)initWithScore:(int)lastScore {
//	NSLog(@"Highscores::init");
	
	if(![super init]) return nil;

//	NSLog(@"lastScore = %d",lastScore);
	
	currentScore = lastScore;

//	NSLog(@"currentScore = %d",currentScore);
	
	CCMenuItem *button1 = [CCMenuItemImage itemFromNormalImage:@"playAgainButton.png" selectedImage:@"playAgainButton.png" target:self selector:@selector(playAgainAction:)];
	CCMenuItem *button2 = [CCMenuItemImage itemFromNormalImage:@"exitGameButton.png" selectedImage:@"exitGameButton" target:self selector:@selector(exitGameAction:)];
	
	CCMenu *menu = [CCMenu menuWithItems: button1, button2, nil];

	[menu alignItemsVerticallyWithPadding:9];
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.width;
    CGFloat screenWidth = screenSize.height;
	menu.position = ccp(screenWidth/2,screenHeight/2);
	
	[self addChild:menu];
	
	return self;
}

- (void)dealloc {
//	NSLog(@"Highscores::dealloc");
	[highscores release];
	[super dealloc];
}

- (void)playAgainAction:(id)sender
{
//	NSLog(@"button1Callback");

	CCTransitionScene *ts = [CCTransitionFade transitionWithDuration:0.5f scene:[Game scene] withColor:ccWHITE];
	[[CCDirector sharedDirector] replaceScene:ts];
}

- (void)exitGameAction:(id)sender
{
	NSLog(@"button2Callback");
    
    
}

@end
