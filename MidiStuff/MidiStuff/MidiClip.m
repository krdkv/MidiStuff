//
//  MidiClip.m
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "MidiClip.h"
#import "MidiMessage.h"

#define kDefaultUpperTimeSignature 4
#define kDefaultLowerTimeSignature 4

@interface MidiClip() {
    NSInteger upperTimeSignature;
    NSInteger lowerTimeSignature;
    NSInteger numberOfPulsesPerQuarterNotes;
    
    NSMutableArray * bars;
    
    NSInteger numberOfPulsesPerBar;
}

- (NSMutableDictionary*) barAtIndex:(NSInteger)index;

@end

@implementation MidiClip

- (id)init
{
    return [self initWithUpperTimeSignature:kDefaultUpperTimeSignature
                      andLowerTimeSignature:kDefaultLowerTimeSignature];
}

- (id) initWithUpperTimeSignature:(NSInteger)upperSignature
            andLowerTimeSignature:(NSInteger)lowerSignature {
    
    self = [super init];
    if (self) {
        upperTimeSignature = upperSignature;
        lowerTimeSignature = lowerSignature != 0 ? lowerSignature : kDefaultLowerTimeSignature;
        numberOfPulsesPerQuarterNotes = kNumberOfPulsesPerQuarterNotes;
        bars = [[NSMutableArray alloc] init];
        
        self.instrument = kArp;
        
        numberOfPulsesPerBar = ( numberOfPulsesPerQuarterNotes * upperTimeSignature * 4 ) /
            lowerTimeSignature;
        
        [bars addObject:[[NSMutableDictionary alloc] init]];
        [bars addObject:[[NSMutableDictionary alloc] init]];
        [bars addObject:[[NSMutableDictionary alloc] init]];
    }
    return self;
}

- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    NSInteger barIndex = pulse / numberOfPulsesPerBar;
    NSMutableDictionary * bar = [self barAtIndex:barIndex];
    
    NSInteger pulseIndex = pulse % numberOfPulsesPerBar;
    
    NSMutableArray * messagesAtPulse = bar[@(pulseIndex)];
    
    if ( messagesAtPulse ) {
        
        for ( MidiMessage * msg in messagesAtPulse ) {
            if ( [msg isEqualToMessage:message] ) {
                [messagesAtPulse removeObject:msg];
                break;
            }
        }
        
    }
}

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    NSInteger barIndex = pulse / numberOfPulsesPerBar;
    NSMutableDictionary * bar = [self barAtIndex:barIndex];
    
    NSInteger pulseIndex = pulse % numberOfPulsesPerBar;
    if ( ! bar[@(pulseIndex)] ) {
        NSMutableArray * pulseArray = [[NSMutableArray alloc] init];
        [bar setObject:pulseArray forKey:@(pulseIndex)];
    }
    
    [(NSMutableArray*)bar[@(pulseIndex)] addObject:message];
}

- (NSArray*) messagesForPulse:(NSInteger)pulse {
    
    if ( bars.count == 0 ) {
        return nil;
    }
    
    while ( pulse >= numberOfPulsesPerBar * bars.count ) {
        pulse -= numberOfPulsesPerBar * bars.count;
    }
    
    if ( pulse < 0 ) {
        return nil;
    }
    
    NSInteger barIndex = pulse / numberOfPulsesPerBar;
    NSDictionary * bar = [self barAtIndex:barIndex];
    
    NSInteger pulseIndex = pulse % numberOfPulsesPerBar;
    
    return bar[@(pulseIndex)];
}

- (CGFloat) progressForPulse:(NSInteger)pulse {
    
    if ( bars.count == 0 ) {
        return 0.f;
    }
    
    while ( pulse >= numberOfPulsesPerBar * bars.count ) {
        pulse -= numberOfPulsesPerBar * bars.count;
    }
    
    if ( pulse < 0 ) {
        return 0.f;
    }
    
    return (CGFloat)pulse / (CGFloat)(numberOfPulsesPerBar * bars.count);
}

- (NSInteger) numberOfPulses {
    return bars.count * numberOfPulsesPerBar;
}

#pragma mark Private

- (NSMutableDictionary*) barAtIndex:(NSInteger)index {
    
//    while ( index >= bars.count ) {
//        [bars addObject:[[NSMutableDictionary alloc] init]];
//    }
    
    if ( index < bars.count ) {
        return bars[index];
    } else {
        return nil;
    }
}

@end