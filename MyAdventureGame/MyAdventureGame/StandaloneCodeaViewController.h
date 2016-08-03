//
//  StandaloneCodeaViewController.h
//  <#MyProjectName#>
//
//  Created by <#AuthorName#> on <#CurrentDate#>
//  Copyright (c) <#AuthorName#>. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CodeaAddon;

typedef enum CodeaViewMode
{
    CodeaViewModeStandard,
    CodeaViewModeFullscreen,
    CodeaViewModeFullscreenNoButtons,
} CodeaViewMode;

@protocol CodeaAddon;

@interface StandaloneCodeaViewController : UIViewController

@property (nonatomic, assign) CodeaViewMode viewMode;
@property (nonatomic, assign) BOOL paused;

- (instancetype) initWithProjectAtPath:(NSString *)path;

- (void) setViewMode:(CodeaViewMode)viewMode animated:(BOOL)animated;

- (void) registerAddon:(id<CodeaAddon>)addon;

@end
