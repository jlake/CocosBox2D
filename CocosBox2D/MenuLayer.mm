//
//  MenuLayer.m
//  cocosShooter
//
//  Created by 欧 on 11/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuLayer.h"
#import "BallLayer.h"
#import "GameLayer.h"
#import "CollisionTestLayer.h"

@implementation MenuLayer

+ (id)scene
{
    CCScene *scene = [CCScene node];
    MenuLayer *layer = [MenuLayer node];
    [scene addChild:layer];
    return scene;
}

- (id)init
{
	if((self=[super initWithColor:ccc4(64, 128, 255, 255)])) {
        [self setupMainMenu];
	}
	return self;
}

-(void)setupMainMenu
{
    NSString *menuFont = @"Marker Felt";
    
    CCLabelTTF *label1 = [CCLabelTTF labelWithString:@"Bounce Ball" fontName:menuFont fontSize:32];
	CCMenuItemImage * menuItem1 = [CCMenuItemLabel itemWithLabel:label1
                                                          target:self
                                                        selector:@selector(loadBallScene:)]; 
    
    CCLabelTTF *label2 = [CCLabelTTF labelWithString:@"Collision Test" fontName:menuFont fontSize:32];
	CCMenuItemImage * menuItem2 = [CCMenuItemLabel itemWithLabel:label2
                                                          target:self
                                                        selector:@selector(loadCollisionTest:)];
    
    CCLabelTTF *label3 = [CCLabelTTF labelWithString:@"Breakout Game" fontName:menuFont fontSize:32];
	CCMenuItemImage * menuItem3 = [CCMenuItemLabel itemWithLabel:label3
                                                          target:self
                                                        selector:@selector(loadBreakoutGame:)]; 

    
	CCMenu * myMenu = [CCMenu menuWithItems:menuItem1, menuItem2, menuItem3, nil];
    
	[myMenu alignItemsVertically];
    
	[self addChild:myMenu];
}

- (void) loadBallScene: (CCMenuItem  *) menuItem 
{
	[[CCDirector sharedDirector] replaceScene: [BallLayer scene]];
}

- (void) loadCollisionTest: (CCMenuItem  *) menuItem 
{
	[[CCDirector sharedDirector] replaceScene: [CollisionTestLayer scene]];
}

- (void) loadBreakoutGame: (CCMenuItem  *) menuItem 
{
	[[CCDirector sharedDirector] replaceScene: [GameLayer scene]];
}

- (void) dealloc
{
	[super dealloc];
}

@end
