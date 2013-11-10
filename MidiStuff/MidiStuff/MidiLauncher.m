//
//  MidiLauncher.m
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "MidiLauncher.h"
#import "MidiClip.h"
#import "MidiMessage.h"
#import "MidiPlayer.h"

#define kDefaultTempo 120
#define kMinimumTempo 60
#define kMaximumTempo 200

@interface MidiLauncher() {
    NSMutableArray * clips;
    NSMutableArray * clipsEnabled;
    
    NSTimer * timer;
    
    NSInteger pulseCounter;
    NSInteger totalNumberOfPulses;
    NSInteger tempo;
    
    MidiPlayer * player;
}

- (void) startTimer;
- (NSInteger) numberOfPulsesForAllClips;

@end

@implementation MidiLauncher

- (id)init
{
    self = [super init];
    if (self) {
        clips = [[NSMutableArray alloc] init];
        clipsEnabled = [[NSMutableArray alloc] init];
        pulseCounter = 0;
        tempo = kDefaultTempo;
        player = [[MidiPlayer alloc] init];
    }
    return self;
}

- (void) start {    
    [self startTimer];
}

- (void) stop {
    [timer invalidate];
    timer = nil;
}

- (void) addMidiClip:(MidiClip*)clip {
    
    if ( ! clip ) {
        return;
    }
    
    [clips addObject:clip];
    [clipsEnabled addObject:@YES];
    if ( [self isRunning] ) {
        [self startTimer];
    }
}

- (void) setTempo:(NSInteger)tempo_ {
    
    if ( tempo_ >= kMinimumTempo && tempo_ <= kMaximumTempo ) {
        tempo = tempo_;
        if ( [self isRunning] ) {
            [self startTimer];
        }
    }
}

- (void) setClipEnabled:(NSInteger)clip enabled:(BOOL)enabled {
    
    if ( clip >= clipsEnabled.count ) {
        return;
    }
    
    clipsEnabled[clip] = @(enabled);
}

#pragma mark Private

- (void) startTimer {
    
    if ( timer ) {
        [timer invalidate];
    }
    
    totalNumberOfPulses = [self numberOfPulsesForAllClips];
    CGFloat timerInterval = (CGFloat)60 / (CGFloat)tempo / (CGFloat)kNumberOfPulsesPerQuarterNotes;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void) timerTick {
    
    for ( NSInteger clipIndex = 0; clipIndex < clips.count; clipIndex++ ) {
        
        MidiClip * clip = clips[clipIndex];
        
        if ( pulseCounter % kNumberOfPulsesPerQuarterNotes == 0 ) {
            if ( self.progressDelegate ) {
                [self.progressDelegate clip:clipIndex progress:[clip progressForPulse:pulseCounter]];
            }
        }
        
        NSArray * messages = [clip messagesForPulse:pulseCounter];
        for ( MidiMessage * message in messages ) {
            
            if ( message.type == kNoteOn && [clipsEnabled[clipIndex] boolValue] == NO ) {
                continue;
            }
            [player forwardMessage:message withInstrument:clip.instrument];
        }
    }
    
    ++pulseCounter;
    if ( pulseCounter == totalNumberOfPulses ) {
        pulseCounter = 0;
    }
}

- (BOOL) isRunning {
    return timer && timer.isValid;
}

- (NSInteger) numberOfPulsesForAllClips {
#warning Hardcoded: should be replaced with lcm for clips
    return 4 * 4 * kNumberOfPulsesPerQuarterNotes;
}

@end
