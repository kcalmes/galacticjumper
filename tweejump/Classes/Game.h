#import "cocos2d.h"
#import "Main.h"

@interface Game : Main
{
	CGPoint bird_pos;
	ccVertex2F bird_vel;
	ccVertex2F bird_acc;	

	float currentPlatformY;
	int currentPlatformTag;
	float currentMaxPlatformStep;
	int currentBonusPlatformIndex;
	int currentBonusType;
	int platformCount;
    NSString* kindOfJump;
	
	BOOL gameSuspended;
	BOOL birdLookingRight;
    BOOL justHitPlatform;
	
	int score;
}

+ (CCScene *)scene;

@end
