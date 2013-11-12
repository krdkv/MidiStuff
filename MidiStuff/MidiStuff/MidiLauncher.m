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
    [player start];
}

- (void) stop {
    [timer invalidate];
    [player stop];
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

- (void) setNumberOfBars:(NSInteger)numberOfBars forClip:(NSInteger)clipNumber {
    
    if ( clipNumber < clips.count ) {
        MidiClip* clip = clips[clipNumber];
        [clip setNumberOfBars:numberOfBars];
        totalNumberOfPulses = [self numberOfPulsesForAllClips];
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
    CGFloat timerInterval = (CGFloat)60 / (CGFloat)tempo / (CGFloat)kNumberOfPulsesPerQuarterNote;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void) timerTick {
    
    for ( NSInteger clipIndex = 0; clipIndex < clips.count; clipIndex++ ) {
        
        MidiClip * clip = clips[clipIndex];
        
        if ( self.progressDelegate ) {
            [self.progressDelegate progressForClip:clipIndex progress:[clip progressForPulse:pulseCounter]];
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

- (void) clipsUpdated {
    totalNumberOfPulses = [self numberOfPulsesForAllClips];
}

- (NSInteger) numberOfPulsesForAllClips {
    
    if ( clips.count == 0 ) {
        return 0;
    } else if ( clips.count == 1 ) {
        return [(MidiClip*)clips[0] numberOfPulses];
    }
    
    NSInteger firstNumberOfPulses = [(MidiClip*)clips[0] numberOfPulses] / kNumberOfPulsesPerQuarterNote;
    NSInteger secondNumberOfPulses = [(MidiClip*)clips[1] numberOfPulses] / kNumberOfPulsesPerQuarterNote;
    
    NSInteger lcm = lowestCommonMultiple(firstNumberOfPulses, secondNumberOfPulses);
    
    for ( int i = 2; i < clips.count; ++i ) {
        NSInteger currentNumberOfPulses = [(MidiClip*)clips[0] numberOfPulses] / kNumberOfPulsesPerQuarterNote;
        lcm = lowestCommonMultiple(lcm, currentNumberOfPulses);
    }
    
    return lcm * kNumberOfPulsesPerQuarterNote;
}

NSInteger lowestCommonMultiple(NSInteger a, NSInteger b)
{
    int n;
    for( n=MIN(a, b) ;; n++)
    {
        if(n%a == 0 && n%b == 0)
            return n;
    }
}

@end
