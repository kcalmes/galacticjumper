#import "cocos2d.h"

//#define RESET_DEFAULTS

#define kFPS 60

#define kNumClouds			4

#define kMinPlatformStep	50
#define kMaxPlatformStep	200
#define kNumPlatforms		7
#define kPlatformTopPadding 20

#define kMinBonusStep		30
#define kMaxBonusStep		50

enum {
	kSpriteManager = 0,
    kCloudsManager = 1,
    kPlatformManager = 2,
	kBird,
	kScoreLabel,
	kCloudsStartTag = 100,
	kPlatformsStartTag = 200,
	kBonusStartTag = 300
};

enum {
	kBonus5 = 0,
	kBonus10,
	kBonus50,
	kBonus100,
	kNumBonuses
};

@interface Main : CCLayer
{
	int currentCloudTag;
}
- (void)resetClouds;
- (void)resetCloud;
- (void)step:(ccTime)dt;
@end
