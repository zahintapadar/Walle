//
#import "WalleScreensaverView.h"

@interface WalleScreensaverView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation WalleScreensaverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setupPlayer];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player pause];
    self.player = nil;
}

- (void)setupPlayer {
    NSString *videoName = @"wallpaper"; // Name of your bundled video file (without extension)
    NSString *videoType = @"mp4";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *videoURL = [bundle URLForResource:videoName withExtension:videoType];
    if (!videoURL) return;

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.player.muted = YES;

    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    self.wantsLayer = YES;
    [self.layer addSublayer:self.playerLayer];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loopVideo:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];

    [self.player play];
}

- (void)loopVideo:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    self.playerLayer.frame = self.bounds;
}

- (void)animateOneFrame {
    // No-op: AVPlayer handles animation.
}

@end
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
