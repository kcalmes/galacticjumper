#import "cocos2d.h"
#import "CCMain.h"

@interface GameOver : Main <UITextFieldDelegate>
+ (CCScene *)gameOverSceneWithScore:(int)lastScore andCombo:(int)currentCombo andCurrentMode:(NSString*) currentMode;
- (id)initWithScore:(int)currentScore andCombo:(int)currentCombo andCurrentMode:(NSString*) currentMode;
@end
