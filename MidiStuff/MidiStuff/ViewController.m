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
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    launcher = [[MidiLauncher alloc] init];
    
    snareClip = [[MidiClip alloc] init];
    snareClip.instrument = kSnare;

//    [snareClip addMessage:[MidiMessage messageWithType:kNoteOn midiKey:24 velocity:80] atPulse:0];
    
    [launcher addMidiClip:snareClip];
    
    self.gridView.delegate = self;
    
    self.midiNoteSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
    self.tempoSlider.transform = CGAffineTransformMakeRotation(- M_PI_2 );
}

- (IBAction)timeLineChanged:(UISlider*)sender {
    
    if ( sender.value < 16 ) {
        sender.value = 12;
    } else if ( sender.value >= 16 && sender.value < 20 ) {
        sender.value = 16;
    } else {
        sender.value = 20;
    }
    
    [self.gridView setHorizontalSize:sender.value];
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
    
    MidiMessage * onMessage = [MidiMessage messageWithType:kNoteOn midiKey:24 + y velocity:120];
    MidiMessage * offMessage = [MidiMessage messageWithType:kNoteOff midiKey:24 + y velocity:120];
    
    if ( filled ) {
        [snareClip addMessage:onMessage atPulse:x * kNumberOfPulsesPerQuarterNotes];
        [snareClip addMessage:offMessage atPulse:x * kNumberOfPulsesPerQuarterNotes + kNumberOfPulsesPerQuarterNotes];
    } else {
        [snareClip removeMessage:onMessage atPulse:x * kNumberOfPulsesPerQuarterNotes];
        [snareClip removeMessage:offMessage atPulse:x * kNumberOfPulsesPerQuarterNotes + kNumberOfPulsesPerQuarterNotes];
    }
    
}

@end
