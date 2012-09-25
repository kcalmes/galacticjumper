#import "cocos2d.h"
#import "Main.h"

@interface Game : Main
{
	CGPoint bird_pos;
	ccVertex2F bird_vel;
	ccVertex2F bird_acc;
    
    CGPoint alien_pos;
    ccVertex2F alien_vel;
	ccVertex2F alien_acc;

	float currentPlatformY;
	int currentPlatformTag;
	float currentMaxPlatformStep;
	int currentBonusPlatformIndex;
	int currentBonusType;
	int platformCount;
	
	BOOL gameSuspended;
	BOOL birdLookingRight;
	
	int score;
    
    //Added by Kory for animation
    CCSprite *_alien;
    CCAction *_jumpAction;
    //BOOL _moving;
    
}

//Added by Kory for animation
@property (nonatomic, retain) CCSprite *alien;
@property (nonatomic, retain) CCAction *jumpAction;


+ (CCScene *)scene;

@end
