#import "TestViewController.h"
#import "TestTableViewCell.h"
#import "ATMicView.h"
#import "TestResultHandler.h"
#import "ATMicView.h"
#import "skegn.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

extern struct skegn *engine;

@interface TestViewController ()<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (nonatomic, strong) ATMicView *micView;  

@property (nonatomic, strong) NSArray *wordsArray;             // English Word Array
@property (nonatomic, strong) NSArray *sentenceArray;          // English Sentence Array
@property (nonatomic, strong) NSArray *paragraphArray;         // English Paragraph Array
@property (nonatomic, strong) NSArray *wordscnArray;           // Chinese Word Array
@property (nonatomic, strong) NSArray *sentencecnArray;        // Chinese Sentence Array
@property (nonatomic, strong) NSArray *paragraphcnArray;       // Chinese Paragraph Array

@property (nonatomic, strong) NSArray *testArray;
@property (nonatomic, strong) NSString *testString;

@property (nonatomic, assign) AudioQueueRef audioQueue;
@property (nonatomic, assign) BOOL isRunning;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44.0f;
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    if([self.coreType isEqual:@"word.eval"]){
        self.testArray = self.wordsArray;
        self.title = @"English Word";
    } else if([self.coreType isEqual:@"sent.eval"]) {
        self.testArray = self.sentenceArray;
        self.title = @"English Sentence";
    } else if([self.coreType isEqual:@"para.eval"]) {
        self.testArray = self.paragraphArray;
        self.title = @"English Paragraph";
    } else if([self.coreType isEqual:@"word.eval.cn"]) {
        self.testArray = self.wordscnArray;
        self.title = @"Chinese Word";
    } else if([self.coreType isEqual:@"sent.eval.cn"]) {
        self.testArray = self.sentencecnArray;
        self.title = @"Chinese Sentence";
    } else if([self.coreType isEqual:@"para.eval.cn"]) {
        self.testArray = self.paragraphcnArray;
        self.title = @"Chinese Paragraph";
    }
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
    self.testString = [self.testArray firstObject];
    self.resultLabel.text = [NSString stringWithFormat:@"Evaluation content：%@", self.testString];
    
}


static int _skegn_callback(const void *usrdata, const char *id, int type, const void *message, int size) {
    NSString *result = [[NSString alloc] initWithUTF8String:(char *)message];
    TestViewController *viewController = (__bridge TestViewController *)usrdata;

    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController showResult:result];
    });

    return 0;
}

- (NSString *)objectToJsonString:(id)object {
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

- (void)startSkegn {
    NSMutableDictionary *appDic = [NSMutableDictionary dictionary];
    [appDic setValue:@"userId" forKey:@"userId"];
    
    NSMutableDictionary *audioDic = [NSMutableDictionary dictionary];
    [audioDic setValue:@"wav" forKey:@"audioType"];
    [audioDic setValue:@16000 forKey:@"sampleRate"];
    [audioDic setValue:@1 forKey:@"channel"];
    [audioDic setValue:@2 forKey:@"sampleBytes"];
    
    NSMutableDictionary *requestDic = [NSMutableDictionary dictionary];
    [requestDic setValue:self.coreType forKey:@"coreType"];
    [requestDic setValue:self.testString forKey:@"refText"];
    
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    [paramDic setValue:appDic forKey:@"app"];
    [paramDic setValue:audioDic forKey:@"audio"];
    [paramDic setValue:requestDic forKey:@"request"];

    [paramDic setValue:@"native" forKey:@"coreProvideType"];
    NSString *jsonString = [self objectToJsonString:paramDic];
    
    char record_id[64] = {0};
    const char *params_char = jsonString.UTF8String;
    printf("====paarams:%s", params_char);
    if (engine) {
        int rv = skegn_start(engine, params_char, record_id, (skegn_callback)_skegn_callback, (__bridge const void *)(self)); //start
        if (rv) {
            NSLog(@"start fail");
            skegn_cancel(engine);
        }
    }
}

static void audioQueueCallback(void * userdata, AudioQueueRef audioQueue, AudioQueueBufferRef buffer, const AudioTimeStamp *startTime, UInt32 packetNum, const AudioStreamPacketDescription *packetDesc) {
    if (!userdata) {
        return;
    }
    TestViewController *viewController;
    if(packetNum > 0) {
        viewController = (__bridge TestViewController *)userdata;
    }
    if(!viewController) {
        return;
    }
    if (buffer->mAudioDataByteSize > 0) {

        if (viewController && viewController.isRunning) {
            skegn_feed(engine, (void *)buffer->mAudioData, buffer->mAudioDataByteSize); //feed audio
        }
    }
    
    if (viewController && viewController.isRunning) {
        AudioQueueEnqueueBuffer(viewController.audioQueue, buffer, 0, NULL);
    } else {
        if (viewController) {
            
            AudioQueueFreeBuffer(viewController.audioQueue, buffer);
        }
    }
}

- (void)stopRecord {
    if(self.isRunning && self.audioQueue){
         NSLog(@"complete");
         
           self.isRunning = NO;
           AudioQueueStop(self.audioQueue, true);
          skegn_stop(engine);  //stop
     }
    
    if (self.audioQueue) {
        AudioQueueDispose(self.audioQueue, true);
        self.audioQueue = nil;
    }
    self.isRunning = NO;
}

- (IBAction)onClickStartTest:(UIButton *)sender {
    sender.selected = !sender.selected;

    if (sender.selected) {
        if ([self.testString length] != 0) {
            self.resultLabel.text = [NSString stringWithFormat:@"Evaluation content：%@", self.testString];
        }
        [self.view addSubview:self.micView];
 
        if(self.isRunning) {
           NSLog(@"wait record end");
           return;
        }
        NSLog(@"start record");
      
        [self startSkegn];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];

         int rv = -1;
         
         AudioStreamBasicDescription audioFormat;
         
         audioFormat.mFormatID = kAudioFormatLinearPCM;
         audioFormat.mSampleRate = 16000;
         audioFormat.mChannelsPerFrame = 1;
         audioFormat.mBitsPerChannel = 16;
         audioFormat.mFramesPerPacket = 1;
         audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel/8;
         audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
         audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
         
         
        if (self.audioQueue) {
             AudioQueueDispose(self.audioQueue, true);
             self.audioQueue = nil;
         }

         rv = AudioQueueNewInput(&audioFormat, audioQueueCallback, (__bridge void * _Nullable)(self), NULL, kCFRunLoopCommonModes, 0, &_audioQueue);
      
         if (rv != noErr) {
             NSLog(@"start record fail:%d", rv);
             return;
         }
         self.isRunning = YES;
         
         UInt32 buffer_size = (UInt32)(audioFormat.mBytesPerFrame * audioFormat.mSampleRate * 100/1000.0);
       
         AudioQueueBufferRef buffer = NULL;
       
         for (int i = 0; i<5; ++i) {
             int rv = AudioQueueAllocateBuffer(self.audioQueue, buffer_size, &buffer);
             if (rv != noErr) {
                 return;
             }
             
             rv = AudioQueueEnqueueBuffer(self.audioQueue, buffer, 0, NULL);
             if (rv != noErr) {
                 return;
             }
         }
        
         rv = AudioQueueStart(self.audioQueue, NULL);
       
         if(rv != 0) {
             self.isRunning = NO;
         }

    }else {
        
        self.resultLabel.text = @"Please wait a moment...";
        [self.micView removeFromSuperview];
        [self stopRecord];
        
    }
}


// evaluation results
- (void)showResult:(NSString *)result {
    NSLog(@"result - %@", result);
    if ([result rangeOfString:@"errId"].length > 0) {  //Error callback
        [self stopRecord];
        self.resultLabel.text = result;
        self.testButton.selected = NO;
        [self.micView removeFromSuperview];
    } else if ([result rangeOfString:@"sound_intensity"].length > 0) {  // Sound intensity callback
        NSError *error;
        NSData *rdata = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:rdata options:NSJSONReadingMutableLeaves  error:&error];
        CGFloat soundIntensity = [[resultDic objectForKey:@"sound_intensity"] floatValue];
        NSLog(@"result - %f", soundIntensity);
        [self.micView updateVoiceViewWithVolume:soundIntensity/100.0f];
        self.resultLabel.text = result;
    } else {  // Callback of evaluation results
        NSString *ret = [TestResultHandler dealWithTestResult:result coreType:self.coreType];
        self.resultLabel.text = [NSString stringWithFormat:@"%@\n\nResult details：%@", ret, result];
    }
}


#pragma mark - TableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.testArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TestCell" forIndexPath:indexPath];
    cell.contentLabel.text = self.testArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.textField.text = @"";
    self.testString = self.testArray[indexPath.row];
    self.resultLabel.text = [NSString stringWithFormat:@"Evaluation content：%@", self.testString];
}

#pragma mark - UITextField

- (void)textFieldDidChange:(UITextField *)textField {
    self.testString = textField.text;
    self.resultLabel.text = [NSString stringWithFormat:@"Evaluation content：%@", textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Init

- (NSArray *)wordsArray {
    if (!_wordsArray) {
        _wordsArray = @[@"hello", @"happy", @"new", @"year", @"merry", @"christmas", @"apple", @"english", @"china"];
    }
    return _wordsArray;
}

- (NSArray *)sentenceArray {
    if (!_sentenceArray) {
        _sentenceArray = @[@"Let me introduce myself.", @"It’s nice meeting you.", @"I’d like to introduce my friend.", @"You mean a lot to me.", @"I’m Looking Forward to It.", @"Today is a great day.", @"Are you making progress?", @"That's a great idea!", @"Please say hello to your mother for me."];
    }
    return _sentenceArray;
}

- (NSArray *)paragraphArray {
    if (!_paragraphArray) {
        _paragraphArray = @[
                            @"This is my room. Near the window there is a desk. I often do my homework at it. You can see some books, some flowers in a vase, a ruler and a pen. On the wall near the desk there is a picture of a cat. There is a clock above the end of my bed. I usually put my shoe under my bed. Of course there is a chair in front of the desk. I sit there and I can see the trees and roads outside.",
                            @"Mom bought me a pair of skating shoes at my fifth birthday. From then on, I developed the hobby of skating. It not only makes me stronger and stronger, but also helps me know many truths of life. I know that it is normal to fall, and if only you can get on your feet again and keep on moving, you are very good!",
                            @"What do you know about the sea? Some people know about it, but others don’t. The sea looks beautiful on a fine sunny day, the sea is very big. In the world, there is more sea than land. Do you know Hainan Island? It’s really very nice. We can see beaches, trees and the sea. We can swim and visit a lot of beautiful places.",
                            @"Computers are changing our life. You can do a lot of things with a computer. Such as, you can use a computer to write articles, watch video CDs, play games and do office work. But the most important use of a computer is to join the Internet.We don’t need to leave home to borrow books from a library or to do shopping in a supermarket.",
                            @"Spring is a delightful season. The temperatures are moderate, and the blooming trees and flowers make the city bright with colors. This is the time when we can begin to wear lighter and more brightly colored clothes and go outdoors more often. Smaller children like to bring their kites out to the spacious square. Also I enjoy going back to the village on this holiday after being in the city for the winter months."];

    }
    return _paragraphArray;
}

- (NSArray *)wordscnArray {
    if (!_wordscnArray) {
        _wordscnArray = @[@"你", @"我", @"开", @"花", @"美", @"丽"];
    }
    return _wordscnArray;
}

- (NSArray *)sentencecnArray {
    if (!_sentencecnArray) {
        _sentencecnArray = @[@"见到你很高兴", @"我喜欢跟你呆在一起", @"你是我最好的朋友", @"周末我们一起去打篮球"];
    }
    return _sentencecnArray;
}

- (NSArray *)paragraphcnArray {
    if (!_paragraphcnArray) {
        _paragraphcnArray = @[
                            @"窗前明月光，疑是地上霜，举头望明月。低头思故乡",
                            @"小草偷偷地从土里钻出来，嫩嫩的，绿绿的。园子里，田野里，瞧去，一大片一大片满是的。坐着，躺着，打两个滚，踢几脚球，赛几趟跑，捉几回迷藏。风轻悄悄的，草软绵绵的。",
                            @"雨是最寻常的，一下就是三两天。可别恼。看，像牛毛，像花针，像细丝，密密地斜织着，人家屋顶上全笼着一层薄烟。树叶子却绿得发亮，小草也青得逼你的眼。傍晚时候，上灯了，一点点黄晕的光，烘托出一片安静而和平的夜。乡下去，小路上，石桥边，有撑起伞慢慢走着的人；还有地里工作的农夫，披着蓑，戴着笠的。他们的草屋，稀稀疏疏的，在雨里静默着。",
                           ];

    }
    return _paragraphcnArray;
}

- (ATMicView *)micView {
    if (!_micView) {
        _micView = [[ATMicView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) lineWidth:2 linceColor:[UIColor whiteColor] colidColor:[UIColor whiteColor]];
        _micView.center = self.view.center;
    }
    return _micView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
