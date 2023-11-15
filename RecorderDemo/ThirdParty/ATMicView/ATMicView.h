#import <UIKit/UIKit.h>

@interface ATMicView : UIView

- (instancetype)initWithFrame:(CGRect)frame lineWidth:(CGFloat)lineWidth linceColor:(UIColor*)lColor colidColor:(UIColor*)cColor;

/**
 *  Set the volume level
 *
 *  @param volume 0.0 ~ 1.0
 */
- (void)updateVoiceViewWithVolume:(float)volume;

@end
