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

#define kDefaultVelocity 80

#define kDefaultInstrument kSnare

struct Pulse {
    NSInteger barIndex;
    NSInteger barOffset;
};
typedef struct Pulse Pulse;

@interface MidiClip() {
    NSInteger upperTimeSignature;
    NSInteger lowerTimeSignature;
    NSInteger numberOfPulsesPerQuarterNote;
    
    NSMutableArray * bars;
    
    NSInteger numberOfPulsesPerBar;
}

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;
- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse;
- (void) barIndex:(NSInteger*)barIndex andBarOffset:(NSInteger*)barOffset forPulse:(NSInteger)pulse;
- (NSInteger) midiNoteForVerticalOffset:(NSInteger)offset;
- (BOOL) messageExistsAtPulse:(NSInteger)pulse message:(MidiMessage*)message;

@end

@implementation MidiClip

- (id)init
{
    return [self initWithNumberOfBars:3];
}

- (id) initWithNumberOfBars:(NSInteger)numberOfBars {
    self = [super init];
    if (self) {
        upperTimeSignature = kDefaultUpperTimeSignature;
        lowerTimeSignature = kDefaultLowerTimeSignature;
        numberOfPulsesPerQuarterNote = kNumberOfPulsesPerQuarterNote;
        bars = [[NSMutableArray alloc] init];
        
        for ( int i = 0; i < numberOfBars; ++i ) {
            [bars addObject:[[NSMutableDictionary alloc] init]];
        }
        
        self.instrument = kDefaultInstrument;
        
        numberOfPulsesPerBar = ( numberOfPulsesPerQuarterNote * upperTimeSignature * 4 ) /
            lowerTimeSignature;
    }
    return self;
}

- (void) setNumberOfBars:(NSInteger)numberOfBars {
    
    if ( bars.count == numberOfBars ) {
        return;
    } else if ( bars.count < numberOfBars ) {
        for ( int i = 0; i < numberOfBars - bars.count; ++i ) {
            [bars addObject:[[NSMutableDictionary alloc] init]];
        }
    } else if ( bars.count > numberOfBars ) {
        for ( int i = bars.count - 1; i >= numberOfBars; --i ) {
            [bars removeObjectAtIndex:i];
        }
    }
    
}

- (NSInteger) numberOfBars {
    return bars.count;
}

- (NSInteger) numberOfPulsesPerBar {
    return numberOfPulsesPerBar;
}

- (void) setCellFilled:(BOOL)filled
  withHorizontalOffset:(NSInteger)hOffset
    withVerticalOffset:(NSInteger)vOffset {
    
    NSInteger pulse = hOffset * numberOfPulsesPerQuarterNote;
    
    NSInteger midiNote = [self midiNoteForVerticalOffset:vOffset];
    
    BOOL leftNeighbourExists = [self leftNeighbourExistsAtPulse:pulse forNote:midiNote];
    
    BOOL rightNeighbourExists = [self rightNeighbourExistsAtPulse:pulse forNote:midiNote];
    
    if ( filled ) {
        
        if ( ! leftNeighbourExists && ! rightNeighbourExists ) {
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        } else if ( leftNeighbourExists && ! rightNeighbourExists ) {
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        } else if ( ! leftNeighbourExists && rightNeighbourExists ) {
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
        } else {
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        }
        
    } else {
        
        if ( ! leftNeighbourExists && ! rightNeighbourExists ) {
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        } else if ( leftNeighbourExists && ! rightNeighbourExists ) {
            [self removeMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
        } else if ( ! leftNeighbourExists && rightNeighbourExists ) {
            [self removeMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        } else {
            [self addMessage:[MidiMessage messageWithType:kNoteOff midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse];
            [self addMessage:[MidiMessage messageWithType:kNoteOn midiKey:midiNote velocity:kDefaultVelocity] atPulse:pulse + numberOfPulsesPerQuarterNote];
        }
        
    }
    
    
}

- (NSArray*) messagesForPulse:(NSInteger)pulse {
    
    NSInteger barIndex, barOffset;
    [self barIndex:&barIndex andBarOffset:&barOffset forPulse:pulse];
    
    if ( barIndex == -1 || barOffset == -1 ) {
        return nil;
    }
    
    if ( barIndex >= bars.count ) {
        return nil;
    }
    
    NSDictionary * bar = bars[barIndex];
    
    return bar[@(barOffset)];
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

#pragma mark Private

- (NSInteger) midiNoteForVerticalOffset:(NSInteger)offset {
    
#warning Snare drum implementation only
    return 24 + offset;
    
}

- (void) removeMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    NSInteger barIndex = pulse / numberOfPulsesPerBar;
    if ( barIndex >= bars.count ) {
        return;
    }
    
    NSMutableDictionary * bar = bars[barIndex];
    
    NSInteger barOffset = pulse % numberOfPulsesPerBar;
    
    NSMutableArray * messagesAtPulse = bar[@(barOffset)];
    
    if ( messagesAtPulse ) {
        for ( MidiMessage * currentMessage in messagesAtPulse ) {
            if ( [currentMessage isEqualToMessage:message] ) {
                [messagesAtPulse removeObject:currentMessage];
                if ( messagesAtPulse.count == 0 ) {
                    [bar removeObjectForKey:@(barOffset)];
                }
                break;
            }
        }
    }
}

- (void) addMessage:(MidiMessage*)message atPulse:(NSInteger)pulse {
    
    NSInteger barIndex = pulse / numberOfPulsesPerBar;
    if ( barIndex >= bars.count ) {
        return;
    }
    
    NSMutableDictionary * bar = bars[barIndex];
    
    NSInteger barOffset = pulse % numberOfPulsesPerBar;
    
    if ( ! bar[@(barOffset)] ) {
        [bar setObject:[[NSMutableArray alloc] init]
                forKey:@(barOffset)];
    }
    
    [(NSMutableArray*)bar[@(barOffset)] addObject:message];
}

- (void) barIndex:(NSInteger*)barIndex
     andBarOffset:(NSInteger*)barOffset
         forPulse:(NSInteger)pulse {
    
    if ( bars.count == 0 ) {
        *barIndex = -1;
        *barOffset = -1;
        return;
    }
    
    while ( pulse >= numberOfPulsesPerBar * bars.count ) {
        pulse -= numberOfPulsesPerBar * bars.count;
    }
    
    if ( pulse < 0 ) {
        *barIndex = -1;
        *barOffset = -1;
        return;
    }
    
    *barIndex = pulse / numberOfPulsesPerBar;
    *barOffset = pulse % numberOfPulsesPerBar;
}

- (BOOL) leftNeighbourExistsAtPulse:(NSInteger)pulse forNote:(NSInteger)note {
    
    NSInteger currentPulse = pulse;
    
    while ( currentPulse >= 0 ) {
        
        NSArray * messages = [self messagesForPulse:currentPulse];
        
        BOOL offMessageExists = NO, onMessageExists = NO;
        
        for ( MidiMessage * currentMessage in messages ) {
            
            if ( currentMessage.midiKey == note ) {
                if ( currentMessage.type == kNoteOn ) {
                    onMessageExists = YES;
                } else if ( currentMessage.type == kNoteOff ) {
                    offMessageExists = YES;
                }
            }
        }
        
        if ( currentPulse == pulse && offMessageExists ) {
            return YES;
        }
        
        if ( currentPulse != pulse && offMessageExists ) {
            return NO;
        }
        
        if ( currentPulse != pulse && onMessageExists ) {
            return YES;
        }
        
        currentPulse -= numberOfPulsesPerQuarterNote;
    }
    
    return NO;
}

- (BOOL) rightNeighbourExistsAtPulse:(NSInteger)pulse forNote:(NSInteger)note {
    
    NSInteger currentPulse = pulse;
    
    while ( currentPulse != numberOfPulsesPerBar * bars.count - numberOfPulsesPerQuarterNote ) {
        
        NSArray * messages = [self messagesForPulse:currentPulse + numberOfPulsesPerQuarterNote];
        
        BOOL offMessageExists = NO, onMessageExists = NO;
        
        for ( MidiMessage * currentMessage in messages ) {
            
            if ( currentMessage.midiKey == note ) {
                if ( currentMessage.type == kNoteOn ) {
                    onMessageExists = YES;
                } else if ( currentMessage.type == kNoteOff ) {
                    offMessageExists = YES;
                }
            }
        }
        
        if ( currentPulse == pulse && onMessageExists ) {
            return YES;
        }
        
        if ( currentPulse != pulse && onMessageExists ) {
            return NO;
        }
        
        if ( currentPulse != pulse && offMessageExists ) {
            return YES;
        }
        
        currentPulse += numberOfPulsesPerQuarterNote;
    }
    
    return NO;
}

- (BOOL) messageExistsAtPulse:(NSInteger)pulse message:(MidiMessage*)message {
    
    NSArray * messages = [self messagesForPulse:pulse];
    
    for ( MidiMessage * currentMessage in messages ) {
        if ( [currentMessage isEqualToMessage:message] ) {
            return YES;
        }
    }
    
    return NO;
}

@end