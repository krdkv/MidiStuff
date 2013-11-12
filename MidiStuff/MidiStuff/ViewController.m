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

enum {
    kSnareGrid = 1,
    kSynthGrid
};

@interface ViewController () {
    MidiLauncher * launcher;
    MidiClip * snareClip;
    MidiClip * synthClip;
    UIView * progressLine;

    NSInteger chosenClip;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    chosenClip = kSnareGrid;
    
    launcher = [[MidiLauncher alloc] init];
    launcher.progressDelegate = self;
    
    snareClip = [[MidiClip alloc] initWithNumberOfBars:4];
    snareClip.instrument = kSnare;
    
    synthClip = [[MidiClip alloc] initWithNumberOfBars:3];
    synthClip.instrument = kArp;
    
    [launcher addMidiClip:snareClip];
    [launcher addMidiClip:synthClip];
    
    self.snareGridView.delegate = self;
    self.snareGridView.horizontalSize = [snareClip numberOfCells];
    
    self.synthGridView.delegate = self;
    self.synthGridView.horizontalSize = [synthClip numberOfCells];
    
    self.midiNoteSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    self.tempoSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    
    progressLine = [[UIView alloc] initWithFrame:CGRectMake(self.snareGridView.frame.origin.x, self.snareGridView.frame.origin.y, 1.f, 588.f)];
    progressLine.backgroundColor = [UIColor blackColor];
    [self.view addSubview:progressLine];
}

- (IBAction)timeLineChanged:(UISlider*)sender {
    
    GridView * gridView = chosenClip == kSnareGrid ? self.snareGridView : self.synthGridView;
    NSInteger clip = chosenClip == kSnareGrid ? 0 : 1;
    
    if ( sender.value < 16 ) {
        sender.value = 12;
        [launcher setNumberOfBars:3 forClip:clip];
        [gridView setHorizontalSize:12];
    } else if ( sender.value >= 16 && sender.value < 20 ) {
        sender.value = 16;
        [launcher setNumberOfBars:4 forClip:clip];
        [gridView setHorizontalSize:16];
    } else {
        sender.value = 20;
        [launcher setNumberOfBars:5 forClip:clip];
        [gridView setHorizontalSize:20];
    }
}

- (IBAction)clipSelected:(UISegmentedControl *)sender {
    
    chosenClip = sender.selectedSegmentIndex == 0 ? kSnareGrid : kSynthGrid;
    
    self.snareGridView.hidden = chosenClip == kSynthGrid;
    self.synthGridView.hidden = chosenClip == kSnareGrid;
    
}

- (IBAction)noteIntervalChanged:(UISlider*)sender {
    
    GridView * gridView = chosenClip == kSnareGrid ? self.snareGridView : self.synthGridView;
    [gridView setVerticalSize:20 + 6 * sender.value];
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
    
    if ( chosenClip == kSnareGrid ) {
        [snareClip setCellFilled:filled withHorizontalOffset:x withVerticalOffset:y];
    } else {
        [synthClip setCellFilled:filled withHorizontalOffset:x withVerticalOffset:y];
    }
}

#pragma mark LauncherProgressDelegate

- (void) progressForClip:(NSInteger)clip progress:(CGFloat)progress {
    
    if ( chosenClip == clip + 1 ) {
        progressLine.frame = CGRectMake(self.snareGridView.frame.origin.x + self.snareGridView.frame.size.width * progress, progressLine.frame.origin.y, progressLine.frame.size.width, progressLine.frame.size.height);
    }
}

@end
