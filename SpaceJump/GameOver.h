#import "cocos2d.h"
#import "CCMain.h"

@interface GameOver : Main <UITextFieldDelegate>
{
	NSString *currentPlayer;
	int currentScorePosition;
	NSMutableArray *highscores;
	UIAlertView *changePlayerAlert;
	UITextField *changePlayerTextField;
}
+ (CCScene *)gameOverSceneWithScore:(int)lastScore andCombo:(int)lastCombo;
- (id)initWithScore:(int)lastScore andCombo:(int)lastCombo;
@end
