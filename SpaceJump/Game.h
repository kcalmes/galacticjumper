#import "cocos2d.h"
#import "CCMain.h"

@interface Game : Main
{
	CGPoint bird_pos;
	ccVertex2F bird_vel;
	ccVertex2F bird_acc;
    
    CGPoint alien_pos;
    ccVertex2F alien_vel;
	ccVertex2F alien_acc;

	float currentPlatformY;
    float currentFall;
	int currentPlatformTag;
	float currentMaxPlatformStep;
	int currentBonusPlatformIndex;
	int currentBonusType;
	int platformCount;
    NSString* kindOfJump;
	
	BOOL gameSuspended;
    BOOL justHitPlatform;
    BOOL hitStarBouns;
	
	int score;
    int comboTally;
    int maxCombo;
    
    //Added by Kory for animation
    CCSprite *_alien;
    //CCAction *_jumpAction;
    //BOOL _moving;
    
}

//Added by Kory for animation
@property (nonatomic, retain) CCSprite *alien;
//@property (nonatomic, retain) CCAction *jumpAction;


+ (CCScene *)scene;

@end
