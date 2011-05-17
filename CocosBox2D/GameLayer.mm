//
//  GameLayer.m
//  CocosBox2D
//
//  Created by 欧 on 11/05/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "MenuLayer.h"

#define PTM_RATIO 32.0

@implementation GameLayer

+ (id)scene
{
    CCScene *scene = [CCScene node];
    GameLayer *layer = [GameLayer node];
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
        
        // Create world
        b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
        bool doSleep = true;
        world = new b2World(gravity, doSleep);
        
        // Create edges arround the entire screen
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0, 0);
        
        groundBody = world->CreateBody(&groundBodyDef);
        
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
        
        // Create sprite
        ball = [CCSprite spriteWithFile:@"Ball.png" rect:CGRectMake(0, 0, 52, 52)];
        ball.position = ccp(100, 100);
        ball.tag = 1;
        [self addChild:ball];

        // Create ball body and shape
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(200/PTM_RATIO, 200/PTM_RATIO);
        ballBodyDef.userData = ball;
        ballBody = world->CreateBody(&ballBodyDef);
        
        // Create circle shape
        b2CircleShape circle;
        circle.m_radius = ball.contentSize.width/2/PTM_RATIO;
        
        // Create shape definition and add to body
        b2FixtureDef ballShapeDef;
        ballShapeDef.shape = &circle;
        ballShapeDef.density = 1.0f;
        ballShapeDef.friction = 0.f;
        ballShapeDef.restitution = 1.0f;
        ballBody->CreateFixture(&ballShapeDef);
        
        // Create paddle
        paddle = [CCSprite spriteWithFile:@"Paddle.png"];
        paddle.position = ccp(winSize.width/2, 50);
        [self addChild:paddle];

        // Create paddle body
        b2BodyDef paddleBodyDef;
        paddleBodyDef.type = b2_dynamicBody;
        paddleBodyDef.position.Set(winSize.width/2/PTM_RATIO, 50/PTM_RATIO);
        paddleBodyDef.userData = paddle;
        paddleBody = world->CreateBody(&paddleBodyDef);

        // Create paddle shape
        b2PolygonShape paddleShape;
        paddleShape.SetAsBox(paddle.contentSize.width/2/PTM_RATIO, paddle.contentSize.height/2/PTM_RATIO);
        
        // Create shape definition and add to body
        b2FixtureDef paddleShapeDef;
        paddleShapeDef.shape = &paddleShape;
        paddleShapeDef.density = 1.0f;
        paddleShapeDef.friction = 0.f;
        paddleShapeDef.restitution = 1.0f;
        paddleFixture = paddleBody->CreateFixture(&paddleShapeDef);
        
        b2Vec2 force = b2Vec2(10, 10);
        ballBody->ApplyLinearImpulse(force, ballBodyDef.position);

        [self schedule:@selector(tick:)];
        
        self.isTouchEnabled = YES;
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

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(mouseJoint != NULL) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    //NSLog(@"ccTouchesBegan locationWorld:(%f, %f)", locationWorld.x, locationWorld.y);
    
    if (paddleFixture->TestPoint(locationWorld)) {
        b2MouseJointDef md;
        md.bodyA = groundBody;
        md.bodyB = paddleBody;
        md.target = locationWorld;
        md.collideConnected = true;
        md.maxForce = 1000.0f * paddleBody->GetMass();
        
        mouseJoint = (b2MouseJoint *)world->CreateJoint(&md);
        paddleBody->SetAwake(true);
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(mouseJoint == NULL) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    //NSLog(@"ccTouchesMoved locationWorld:(%f, %f)", locationWorld.x, locationWorld.y);

    mouseJoint->SetTarget(locationWorld);
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(mouseJoint) {
        world->DestroyJoint(mouseJoint);
        mouseJoint = NULL;
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(mouseJoint) {
        world->DestroyJoint(mouseJoint);
        mouseJoint = NULL;
    }
}

- (void)dealloc {
    delete world;
    world = NULL;
    groundBody = NULL;
    bottomFixture = NULL;
    ballFixture = NULL;
    
    ball = NULL;
    ballBody = NULL;

    [super dealloc];
}

@end
