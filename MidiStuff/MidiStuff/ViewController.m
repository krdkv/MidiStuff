//
//  ViewController.m
//  MidiStuff
//
//  Created by Nick on 09/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "ViewController.h"
#import "GridView.h"

@interface ViewController () {
    
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gridView.delegate = self;
    
    self.midiNoteSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    self.tempoSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
}

- (IBAction)timeLineChanged:(UISlider*)sender {
    [self.gridView setHorizontalSize:12 + 8 * sender.value];
}

- (IBAction)noteIntervalChanged:(UISlider*)sender {
    [self.gridView setVerticalSize:20 + 6 * sender.value];
}

- (IBAction)tempoChanged:(UISlider *)sender {
    
}

#pragma mark GridViewDelegate

- (void) cellGotFilled:(BOOL)filled onX:(NSInteger)x onY:(NSInteger)y {
    
}

@end
