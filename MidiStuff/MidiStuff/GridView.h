//
//  GridView.h
//  MidiStuff
//
//  Created by Nick on 09/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GridViewDelegate

- (void) cellGotFilled:(BOOL)filled onX:(NSInteger)x onY:(NSInteger)y;

@end

@interface GridView : UIView

@property (nonatomic, assign) NSInteger horizontalSize;
@property (nonatomic, assign) NSInteger verticalSize;

@property (nonatomic, assign) UIColor * filledIntervalColor;

@property (nonatomic, strong) id<GridViewDelegate> delegate;

@end
