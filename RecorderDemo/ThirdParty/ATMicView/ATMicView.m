#import "ATMicView.h"

#define AT_PI 3.14159265359
#define AT_RADIANS(number)  ((AT_PI * number)/ 180)

@interface ATMicView ()


@property (nonatomic,strong) UIView * outsideLineView;

@property (nonatomic,strong,nullable) CAShapeLayer * outsideLineLayer;

@property (nonatomic,strong) UIView * colidView;

@property (nonatomic,strong,nullable) CAShapeLayer * colidLayer;

@property (nonatomic,strong) UIView * arcView;

@property (nonatomic,strong,nullable) CAShapeLayer * arcLayer;

@property (nonatomic,assign) CGFloat lineWidth;

@property (nonatomic,strong) UIColor * lineColor;

@property (nonatomic,strong) UIColor * colidColor;

@property (nonatomic,strong) UIView * cenLineView;

@property (nonatomic,strong) CAShapeLayer * cenLineLayer;

@property (nonatomic,strong) UIView * bomLineView;

@property (nonatomic,strong) CAShapeLayer * bomLineLayer;

@end

@implementation ATMicView

- (instancetype)initWithFrame:(CGRect)frame lineWidth:(CGFloat)lineWidth linceColor:(UIColor*)lColor colidColor:(UIColor*)cColor {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6f];
        self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = YES;
        self.lineColor = lColor;
        self.colidColor = cColor;
        self.lineWidth = lineWidth;
        [self setUp];
    }
    return self;
}

- (void)setUp {
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    CGFloat topHeight = 0.7 * height;
    CGFloat bottomHeight = 0.3 * height;
    
    // Inside the microphone
    self.colidView = [[UIView alloc] initWithFrame:CGRectMake(width*0.38, topHeight*0.15, width*0.24, topHeight*0.7)];
    self.colidView.layer.cornerRadius = self.colidView.frame.size.width*0.4;
    self.colidView.clipsToBounds = YES;
    self.colidLayer = [self drawOutSideLine:CGRectMake(0, 0, self.colidView.frame.size.width, 0) color:self.colidColor isFill:YES];
    [self.colidView.layer addSublayer:self.colidLayer];
    [self addSubview:self.colidView];
    
    // The border of the microphone
    self.outsideLineView = [[UIView alloc] initWithFrame:CGRectMake(width*0.38, topHeight*0.15, width*0.24, topHeight*0.7)];
    self.outsideLineLayer = [self drawOutSideLine:CGRectMake(0, 0, self.outsideLineView.frame.size.width, self.outsideLineView.frame.size.height) color:self.lineColor isFill:NO];
    [self.outsideLineView.layer addSublayer:self.outsideLineLayer];
    [self addSubview:self.outsideLineView];
    
    // Microphone arc
    self.arcView = [[UIView alloc] initWithFrame:CGRectMake(0, topHeight*0.09, width, topHeight*0.6)];
    self.arcLayer = [self drawARCLine:self.arcView.center frame:self.arcView.frame color:self.lineColor];
    [self.arcView.layer addSublayer:self.arcLayer];
    [self addSubview:self.arcView];
    
    self.cenLineView = [[UIView alloc]initWithFrame:CGRectMake(width/2 - self.lineWidth/2, topHeight, self.lineWidth, bottomHeight*0.6)];
    self.cenLineLayer = [self drawOutSideLine:self.cenLineView.bounds color:self.lineColor];
    [self.cenLineView.layer addSublayer:self.cenLineLayer];
    [self addSubview:self.cenLineView];
    
    self.bomLineView = [[UIView alloc]initWithFrame:CGRectMake(width*0.3, bottomHeight*0.6 - self.lineWidth/2 + topHeight, width*0.4, self.lineWidth)];
    self.cenLineLayer = [self drawOutSideLine:self.bomLineView.bounds color:self.lineColor];
    [self.bomLineView.layer addSublayer:self.cenLineLayer];
    [self addSubview:self.bomLineView];
}


- (CAShapeLayer*)drawARCLine:(CGPoint)point frame:(CGRect)frame color:(UIColor*)color {
    CAShapeLayer * Layer = [CAShapeLayer new];
    Layer.fillColor = nil;
    Layer.strokeColor = color.CGColor;
    Layer.frame = frame;
    Layer.lineWidth = self.lineWidth;
    Layer.lineCap = kCALineCapRound;
    
    Layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(point.x, point.y) radius:frame.size.width*0.3 startAngle:AT_RADIANS(-5) endAngle:AT_RADIANS(185) clockwise:YES].CGPath;
    return Layer;
}

- (CAShapeLayer*)drawOutSideLine:(CGRect)frame color:(UIColor*)color isFill:(BOOL)fill {
    CAShapeLayer * Layer = [CAShapeLayer new];
    if (fill) {
        Layer.fillColor = color.CGColor;
        Layer.strokeColor = nil;
    }
    else{
        Layer.fillColor = nil;
        Layer.strokeColor = color.CGColor;
    }
    
    Layer.frame = frame;
    Layer.lineWidth = self.lineWidth;
    Layer.lineCap = kCALineCapRound;
    
    Layer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, frame.size.height)  cornerRadius:frame.size.width*0.4].CGPath;
    return Layer;
}

- (CAShapeLayer*)drawOutSideLine:(CGRect)frame color:(UIColor*)color {
    CAShapeLayer * Layer = [CAShapeLayer new];
    Layer.fillColor = color.CGColor;
    Layer.strokeColor = nil;
    Layer.frame = frame;
    Layer.lineWidth = self.lineWidth;
    Layer.lineCap = kCALineCapRound; 
    
    Layer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, frame.size.height)  cornerRadius:frame.size.width*0.4].CGPath;
    return Layer;
}

- (void)updateVoiceViewWithVolume:(float)volume {
    CGFloat height = self.colidView.frame.size.height;
    CGFloat newHeight = height*volume;
    CGFloat width = self.colidView.frame.size.width;
    
    //    NSLog(@"%f",newHeight);
    self.colidLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, height - newHeight , width , newHeight) cornerRadius:0].CGPath;
}

@end
