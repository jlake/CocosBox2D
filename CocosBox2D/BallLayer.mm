//
//  BallLayer.m
//  CocosBox2D
//
//  Created by 欧 on 11/05/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BallLayer.h"
#import "MenuLayer.h"

#define PTM_RATIO 32.0

@implementation BallLayer

+ (id)scene
{
    CCScene *scene = [CCScene node];
    BallLayer *layer = [BallLayer node];
    [scene addChild:layer];
    return scene;
}

-(void) setupGameMenu
{
    CCLabelTTF *label1 = [CCLabelTTF labelWithString:@"<<Menu" fontName:@"Marker Felt" fontSize:20];
    label1.color = ccc3(0, 0, 255);
	CCMenuItemImage * menuItem1 = [CCMenuItemLabel itemWithLabel:label1
                                                          target:self
                                                        selector:@selector(loadMenuScene:)]; 
	CCMenu *menu = [CCMenu menuWithItems:menuItem1, nil];
    int margin = 5;
    menu.position = ccp(label1.contentSize.width/2 + margin, winSize.height - label1.contentSize.height/2 - margin);
	[menu alignItemsHorizontally];
    
	[self addChild:menu];
}

- (void) loadMenuScene: (CCMenuItem  *) menuItem 
{
    [[CCDirector sharedDirector] replaceScene: [MenuLayer scene]];
}

- (id)init
{
    if ((self = [super init])) {
        winSize = [CCDirector sharedDirector].winSize;
        [self setupGameMenu];
        
        // Create sprite
        ball = [CCSprite spriteWithFile:@"Ball.png" rect:CGRectMake(0, 0, 52, 52)];
        ball.position = ccp(100, 100);
        [self addChild:ball];
        
        // Create world
        b2Vec2 gravity = b2Vec2(0.0f, -30.0f);
        bool doSleep = true;
        world = new b2World(gravity, doSleep);
        
        // Create edges arround the entire screen
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0, 0);
        
        b2Body *groundBody = world->CreateBody(&groundBodyDef);
        
        b2PolygonShape groundBox;
        
        b2FixtureDef boxShapeDef;
        boxShapeDef.shape = &groundBox;
        
        CGSize box;
        box.width = winSize.width/PTM_RATIO;
        box.height = winSize.height/PTM_RATIO;
        
        groundBox.SetAsEdge(b2Vec2(0, 0), b2Vec2(box.width, 0));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundBox.SetAsEdge(b2Vec2(0, 0), b2Vec2(0, box.height));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundBox.SetAsEdge(b2Vec2(0, box.height), b2Vec2(box.width, box.height));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundBox.SetAsEdge(b2Vec2(box.width, box.height), b2Vec2(box.width, 0));
        groundBody->CreateFixture(&boxShapeDef);
        
        // Create ball body and shape
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(200/PTM_RATIO, 200/PTM_RATIO);
        ballBodyDef.userData = ball;
        body = world->CreateBody(&ballBodyDef);
        
        b2CircleShape circle;
        circle.m_radius = 26.0/PTM_RATIO;
        
        b2FixtureDef ballShapeDef;
        ballShapeDef.shape = &circle;
        ballShapeDef.density = 1.0f;
        ballShapeDef.friction = 0.2f;
        ballShapeDef.restitution = 0.8f;
        body->CreateFixture(&ballShapeDef);
        
        self.isAccelerometerEnabled = YES;

        [self schedule:@selector(tick:)];
        
    }
    return self;
}

- (void)tick:(ccTime)dt
{
    world->Step(dt, 10, 10);
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        if(b->GetUserData() != NULL) {
            CCSprite *ballData = (CCSprite *) b->GetUserData();
            b2Vec2 pos = b->GetPosition();
            ballData.position = ccp(pos.x * PTM_RATIO, pos.y * PTM_RATIO);
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
        
    }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    NSLog(@"accelerometer");
    b2Vec2 gravity(-acceleration.y * 15, acceleration.x * 15);
    world->SetGravity(gravity);
}

- (void)dealloc {
    delete world;
    body = NULL;
    world = NULL;
    
    [super dealloc];
}

@end
