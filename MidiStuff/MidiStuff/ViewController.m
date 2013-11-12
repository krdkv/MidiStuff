//
//  ViewController.m
//  MidiStuff
//
//  Created by Nick on 09/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "ViewController.h"
#import "GridView.h"
#import "MidiLauncher.h"
#import "MidiMessage.h"
#import "MidiClip.h"

@interface ViewController () {
    MidiLauncher * launcher;
    MidiClip * snareClip;
    MidiClip * synthClip;
    UIView * progressLine;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    launcher = [[MidiLauncher alloc] init];
    launcher.progressDelegate = self;
    
    snareClip = [[MidiClip alloc] init];
    snareClip.instrument = kSnare;
    
    synthClip = [[MidiClip alloc] initWithNumberOfBars:4];
    synthClip.instrument = kArp;
    
    [launcher addMidiClip:snareClip];
    [launcher addMidiClip:synthClip];
    
    self.gridView.delegate = self;
    
    self.midiNoteSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    self.tempoSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    
    progressLine = [[UIView alloc] initWithFrame:CGRectMake(self.gridView.frame.origin.x, self.gridView.frame.origin.y, 1.f, 588.f)];
    progressLine.backgroundColor = [UIColor blackColor];
    [self.view addSubview:progressLine];
}

- (IBAction)timeLineChanged:(UISlider*)sender {
    
    if ( sender.value < 16 ) {
        sender.value = 12;
        [launcher setNumberOfBars:3 forClip:0];
        [self.gridView setHorizontalSize:12];
    } else if ( sender.value >= 16 && sender.value < 20 ) {
        sender.value = 16;
        [launcher setNumberOfBars:4 forClip:0];
        [self.gridView setHorizontalSize:16];
    } else {
        sender.value = 20;
        [launcher setNumberOfBars:5 forClip:0];
        [self.gridView setHorizontalSize:20];
    }
}

- (IBAction)noteIntervalChanged:(UISlider*)sender {
    [self.gridView setVerticalSize:20 + 6 * sender.value];
}

- (IBAction)tempoChanged:(UISlider *)sender {
    [launcher setTempo:sender.value];
}

- (IBAction)playPressed:(UIButton *)sender {
    [launcher start];
}

- (IBAction)pausePressed:(UIButton *)sender {
    [launcher stop];
}

#pragma mark GridViewDelegate

- (void) cellGotFilled:(BOOL)filled onX:(NSInteger)x onY:(NSInteger)y {
    [snareClip setCellFilled:filled withHorizontalOffset:x withVerticalOffset:y];
}

#pragma mark LauncherProgressDelegate

- (void) progressForClip:(NSInteger)clip progress:(CGFloat)progress {
    
    if ( clip == 0 ) {
        
        progressLine.frame = CGRectMake(self.gridView.frame.origin.x + self.gridView.frame.size.width * progress, progressLine.frame.origin.y, progressLine.frame.size.width, progressLine.frame.size.height);
        
    }
    
}

@end
