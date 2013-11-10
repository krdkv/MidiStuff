//
//  GridView.m
//  MidiStuff
//
//  Created by Nick on 09/11/2013.
//  Copyright (c) 2013 Nick. All rights reserved.
//

#import "GridView.h"

#define kDefaultMainGridColor [UIColor lightGrayColor]
#define kDefaultSubGridColor  [UIColor grayColor]
#define kDefaultFillColor     [UIColor colorWithRed:0.364f green:0.53f blue:0.188f alpha:1.f]

#define kDefaultHorizontalSize 12
#define kDefaultVerticalSize   20

struct Cell {
    NSInteger x;
    NSInteger y;
};
typedef struct Cell Cell;


@interface GridView() {
    CGFloat cellWidth;
    CGFloat cellHeight;
    
    Cell currentBlock;
    NSMutableDictionary * filledCells;
}

@end

@implementation GridView

@synthesize horizontalSize = _horizontalSize;
@synthesize verticalSize   = _verticalSize;

- (id)init
{
    self = [super init];
    if (self) {
        [self setDefaultSettings];
    }
    return self;
}

- (void) awakeFromNib {
    [self setDefaultSettings];
}

- (void) setDefaultSettings {
    _horizontalSize = kDefaultHorizontalSize;
    _verticalSize   = kDefaultVerticalSize;
    self.backgroundColor = [UIColor clearColor];
    self.multipleTouchEnabled = NO;
    self.userInteractionEnabled = YES;
    currentBlock.x = -1;
    currentBlock.y = -1;
    filledCells = [[NSMutableDictionary alloc] init];
}

- (void) setHorizontalSize:(NSInteger)horizontalSize {
    _horizontalSize = horizontalSize;
    [self checkForOutOfBorderCells];
    [self setNeedsDisplay];
}

- (void) setVerticalSize:(NSInteger)verticalSize {
    _verticalSize = verticalSize;
    [self checkForOutOfBorderCells];
    [self setNeedsDisplay];
}

- (void) checkForOutOfBorderCells {
    
    NSMutableArray * cellsToDelete = [[NSMutableArray alloc] init];
    
    for ( NSValue * key in filledCells.allKeys ) {
        Cell cell;
        [key getValue:&cell];
        if ( cell.x > _horizontalSize || cell.y > _verticalSize ) {
            if ( self.delegate ) {
                [self.delegate cellGotFilled:NO onX:cell.x onY:cell.y];
            }
            [cellsToDelete addObject:key];
        }
    }
    
    for ( NSValue * key in cellsToDelete ) {
        [filledCells removeObjectForKey:key];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for ( UITouch * touch in touches ) {
        [self registerTouch:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event; {
    for ( UITouch * touch in touches ) {
        [self registerTouch:touch];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    currentBlock.x = -1;
    currentBlock.y = -1;
}

- (void) registerTouch:(UITouch*)touch {
    
    CGFloat x = [touch locationInView:self].x;
    CGFloat y = [touch locationInView:self].y;
    
    if ( x < 0 || x > self.frame.size.width || y < 0 || y > self.frame.size.height ) {
        return;
    }
    
    NSInteger blockX = -1, blockY = -1;
    
    for ( int i = 0; i < _horizontalSize; ++i ) {
        if ( x >= i * cellWidth && x < (i+1) * cellWidth ) {
            blockX = i;
            break;
        }
    }
    
    for ( int i = 0; i < _verticalSize; ++i ) {
        if ( y >= i * cellHeight && y < (i+1) * cellHeight ) {
            blockY = _verticalSize - i;
            break;
        }
    }
    
    if ( blockX == -1 || blockY == -1 ) {
        return;
    }
    
    if ( currentBlock.x == blockX && currentBlock.y == blockY ) {
        return;
    }
    
    currentBlock.x = blockX;
    currentBlock.y = blockY;
    
    [self toggleBlock:currentBlock];
}

- (void) toggleBlock:(Cell)block {
    
    NSValue * key = [NSValue value:&block withObjCType:@encode(Cell)];
    
    if ( ! filledCells[key] ) {
        filledCells[key] = @YES;
        if ( self.delegate ) {
            [self.delegate cellGotFilled:YES onX:block.x onY:block.y];
        }
    } else {
        if ( self.delegate ) {
            [self.delegate cellGotFilled:NO onX:block.x onY:block.y];
        }
        [filledCells removeObjectForKey:key];
    }
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGRect rectangle = CGRectMake(0.f, 0.f, self.frame.size.width, self.frame.size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, kDefaultMainGridColor.CGColor);
    CGContextFillRect(context, rectangle);
    
    cellWidth = self.frame.size.width / _horizontalSize;
    cellHeight = self.frame.size.height / _verticalSize;

    CGContextSetFillColorWithColor(context, kDefaultSubGridColor.CGColor);
    
    for ( int i = 0; i < _horizontalSize; ++i ) {
        for ( int j = 0; j < _verticalSize; ++j ) {
            if ( (i + j) % 2 == 1 ) {
                CGRect rectangle = CGRectMake(i * cellWidth, j * cellHeight, cellWidth, cellHeight);
                CGContextFillRect(context, rectangle);
            }
        }
    }
    
    CGContextSetFillColorWithColor(context, kDefaultFillColor.CGColor);
    
    for ( NSValue * key in filledCells.allKeys ) {
        Cell cell;
        [key getValue:&cell];
        CGRect rectangle = CGRectMake(cell.x * cellWidth, (_verticalSize - cell.y) * cellHeight, cellWidth, cellHeight);
        CGContextFillRect(context, rectangle);
    }
}

@end
