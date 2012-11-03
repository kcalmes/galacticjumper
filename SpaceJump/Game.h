#import "cocos2d.h"
#import "CCMain.h"

@interface Game : Main
{
    int screenWidth;
    int screenHeight;
    
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
    int dissapearingPlatformTag;
    NSString* kindOfJump;
	
	BOOL gameSuspended;
    BOOL justHitPlatform;
    BOOL hitStarBouns;
    BOOL hasHitStartPlatform;
	
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
