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
    float numOfSeconds;
	int currentPlatformTag;
	float currentMaxPlatformStep;
	int currentBonusPlatformIndex;
	int currentBonusType;
	int platformCount;
    int dissapearingPlatformTag;
    int easyModePad;
    int numOfMinutes;
    int startGameAnimations;
    
    NSString* kindOfJump;
    NSString* gameMode;
	
	BOOL gameSuspended;
    BOOL justHitPlatform;
    BOOL hitStarBounus;
    BOOL hasHitStartPlatform;
    BOOL easyMode;
    BOOL timedMode;
    BOOL gamePaused;
    BOOL performingStartAnimations;
	
	int score;
    int comboTally;
    int maxCombo;
    
    //Added by Kory for animation
    CCSprite *_alien;
    //CCAction *_jumpAction;
    //BOOL _moving;

    CCSprite *pauseScreen;
    CCMenu *pauseButton;
    CCMenu *pauseScreenMenu;
    
}

//Added by Kory for animation
@property (nonatomic, retain) CCSprite *alien;
//@property (nonatomic, retain) CCAction *jumpAction;


+ (CCScene *)sceneWithMode:(NSString*) mode;

@end
