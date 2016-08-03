//
//  iAdsAddon.m
//

#import <iAd/iAd.h>

#import "iAdsAddon.h"

#import "StandaloneCodeaViewController.h"

#import "lua.h"
#import "lauxlib.h"

@interface iAdsAddon ()<ADBannerViewDelegate>

@property (atomic, assign) BOOL isBannerVisible;
@property (atomic, assign) BOOL showBannerFromTop;
@property (atomic, assign) BOOL adsAllowed;

@property (strong, nonatomic) ADBannerView *bannerView;

@end

@implementation iAdsAddon

#pragma mark - Singleton

+ (instancetype) sharedInstance
{
    static id _sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialise our Instance Variables
        _isBannerVisible = NO;
        _showBannerFromTop = YES;
        _adsAllowed = NO;
        
        //  Initialise our iAd Banner View
        CGRect frame = CGRectZero;
        
        _bannerView = [[ADBannerView alloc] initWithFrame: frame];
        [_bannerView setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        
        _bannerView.delegate = self;
    }
    return self;
}

#pragma mark - Codea Addon Protocol Implementation

- (void) codea:(StandaloneCodeaViewController*)codeaController didCreateLuaState:(struct lua_State*)L
{
    NSLog(@"iAdAddOn Registering Functions");
    
    //  Register the iAd functions, defined below
    lua_register(L, "showAdFromTop", showAdFromTop);
    lua_register(L, "showAdFromBottom", showAdFromBottom);
    lua_register(L, "hideAd", hideAd);
}

#pragma mark - iAd View Display / Hiding Methods

- (void)showBannerViewAnimated:(BOOL)animated
{
    if ([self.bannerView isBannerLoaded])
    {
        if (_adsAllowed) {
            //  We only display the banner View if it has ads loaded and isn't already visible.
            //  Set the banner view starting position as off screen.
            
            CGRect frame = _bannerView.frame;
            
            if (_showBannerFromTop)
            {
                frame.origin.y = 0.0f - _bannerView.frame.size.height;
            }
            else
            {
                frame.origin.y = CGRectGetMaxY(self.codeaController.view.bounds);
            }
            
            _bannerView.frame = frame;
            
            // Set banner View final position to animate to.
            
            if (_showBannerFromTop)
            {
                frame.origin.y = 0;
            }
            else
            {
                frame.origin.y -= frame.size.height;
            }
            
            if (animated)
            {
                [UIView animateWithDuration: 0.5 animations: ^{self.bannerView.frame = frame;}];
            }
            else
            {
                self.bannerView.frame = frame;
            }
            
            _isBannerVisible = YES;
        }
        else
        {
            NSLog(@"Ads should not be shown right now");
            
            [self hideBannerViewAnimated: NO];
        }
    }
    else
    {
        NSLog(@"showBannerViewAnimated: Unable to display banner, no Ads loaded.");
    }
}

- (void)hideBannerViewAnimated:(BOOL)animated
{
    if (_isBannerVisible || !_adsAllowed)
    {
        CGRect frame = self.bannerView.frame;
        
        if (_showBannerFromTop)
        {
            frame.origin.y -= frame.size.height;
        }
        else
        {
            frame.origin.y = CGRectGetMaxY(self.codeaController.view.bounds);
        }
        
        if (animated)
        {
            [UIView animateWithDuration: 0.5 animations: ^{self.bannerView.frame = frame;}];
        }
        else
        {
            self.bannerView.frame = frame;
        }
        
        _isBannerVisible = NO;
    }
}

#pragma mark - Lua C Functions

static int showAdFromTop(struct lua_State *state)
{
    //This will be called on the Lua thread in 2.1
    
    [[iAdsAddon sharedInstance] setAdsAllowed: YES];
    [[iAdsAddon sharedInstance] setShowBannerFromTop: YES];
    
    //Ensure we dispach to main to touch any UI stuff!
    dispatch_async(dispatch_get_main_queue(), ^{
        [[iAdsAddon sharedInstance] showBannerViewAnimated: YES];
    });
    
    return 0;
}

static int showAdFromBottom(struct lua_State *state)
{
    //This will be called on the Lua thread in 2.1
    
    [[iAdsAddon sharedInstance] setAdsAllowed: YES];
    [[iAdsAddon sharedInstance] setShowBannerFromTop: NO];
    
    //Ensure we dispach to main to touch any UI stuff!
    dispatch_async(dispatch_get_main_queue(), ^{
        [[iAdsAddon sharedInstance] showBannerViewAnimated: YES];
    });
    
    return 0;
}

static int hideAd(struct lua_State *state)
{
    //This will be called on the Lua thread in 2.1    
    
    [[iAdsAddon sharedInstance] setAdsAllowed: NO];

    //Ensure we dispach to main to touch any UI stuff!
    dispatch_async(dispatch_get_main_queue(), ^{
        [[iAdsAddon sharedInstance] hideBannerViewAnimated: YES];
    });
    
    return 0;
}

#pragma mark - iAd Banner View Delegate

//  Your application implements this method to be notified when a new advertisement is ready for display.

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"Banner View loaded Ads for display.");
    NSLog(@"Active View Controller: %@", self.codeaController.class);
    
    //  Add our banner view to the CodeaViewController view, if we haven't already.
    if ( ![self.codeaController.view.subviews containsObject: _bannerView] )
    {
        [self.codeaController.view addSubview: _bannerView];
    }
    
    [self showBannerViewAnimated: YES];
}

//  This method is triggered when an advertisement could not be loaded from the iAds system
//  (perhaps due to a network connectivity issue).

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"bannerview failed to receive iAd error: %@", [error localizedDescription]);
    
    [self hideBannerViewAnimated: YES];
}

//  This method is triggered when the banner confirms that an advertisement is available but before the ad is
//  downloaded to the device and is ready for presentation to the user.

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    
}

//  This method is triggered when the user touches the iAds banner in your application. If the willLeave argument
//  passed through to the method is YES then your application will be placed into the background while the user is
//  taken elsewhere to interact with or view the ad. If the argument is NO then the ad will be superimposed over your
//  running application.

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    self.codeaController.paused = YES;
    
    NSLog(@"Ad being displayed - Codea paused.");
    
    return YES;
}

//  This method is called when the ad view removes the ad content currently obscuring the application interface.
//  If the application was paused during the ad view session this method can be used to resume activity.

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    self.codeaController.paused = NO;
    
    NSLog(@"Ad dismissed - Codea running.");
}

@end
