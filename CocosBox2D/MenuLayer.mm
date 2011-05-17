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
    CCLabelTTF *label1 = [CCLabelTTF labelWithString:@"Bounce Ball" fontName:@"Marker Felt" fontSize:32];
	CCMenuItemImage * menuItem1 = [CCMenuItemLabel itemWithLabel:label1
                                                          target:self
                                                        selector:@selector(loadBallScene:)]; 
    
    CCLabelTTF *label2 = [CCLabelTTF labelWithString:@"Brakeout Game" fontName:@"Marker Felt" fontSize:32];
	CCMenuItemImage * menuItem2 = [CCMenuItemLabel itemWithLabel:label2
                                                          target:self
                                                        selector:@selector(loadGameScene:)]; 
    
	CCMenu * myMenu = [CCMenu menuWithItems:menuItem1, menuItem2, nil];
    
	[myMenu alignItemsVertically];
    
	[self addChild:myMenu];
}

- (void) loadBallScene: (CCMenuItem  *) menuItem 
{
	[[CCDirector sharedDirector] replaceScene: [BallLayer scene]];
}

- (void) loadGameScene: (CCMenuItem  *) menuItem 
{
	[[CCDirector sharedDirector] replaceScene: [GameLayer scene]];
}

- (void) dealloc
{
	[super dealloc];
}

@end
