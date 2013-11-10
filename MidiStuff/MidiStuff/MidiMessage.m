//
//  MidiMessage.m
//  MidiEngine
//
//  Created by Nick on 07/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "MidiMessage.h"

#define kMessageNames @[@"ON", @"OFF"]

@implementation MidiMessage

+ (MidiMessage*) messageWithType:(MidiMessageType)type
                        midiKey:(NSInteger)midiKey
                       velocity:(NSInteger)velocity {
    
    return [[MidiMessage alloc] initWithType:type midiKey:midiKey velocity:velocity];
}

- (id)initWithType:(MidiMessageType)type_
           midiKey:(NSInteger)midiKey_
          velocity:(NSInteger)velocity_
{
    self = [super init];
    if (self) {
        self.type = type_;
        self.velocity = velocity_;
        self.midiKey = midiKey_;
    }
    return self;
}

- (BOOL) isEqualToMessage:(MidiMessage*)message {
    return message.type == self.type && self.velocity == message.velocity &&
        message.midiKey == self.midiKey;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ key:%ld velocity:%ld>", kMessageNames[self.type], self.midiKey, self.velocity];
}

@end
