//
//  GameLayer.m
//  CocosBox2D
//
//  Created by 欧 on 11/05/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "MenuLayer.h"
#import "SimpleAudioEngine.h"

#define PTM_RATIO 32.0
#define TAG_BALL 1
#define TAG_BLOCK 2
#define TAG_PADDLE 3

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

- (void) initWorld
{
    if(world != NULL) {
        delete world;
    }

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
    bottomFixture = groundBody->CreateFixture(&boxShapeDef);
    
    groundBox.SetAsEdge(b2Vec2(0, 0), b2Vec2(0, box.height));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundBox.SetAsEdge(b2Vec2(0, box.height), b2Vec2(box.width, box.height));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundBox.SetAsEdge(b2Vec2(box.width, box.height), b2Vec2(box.width, 0));
    groundBody->CreateFixture(&boxShapeDef);
    
    startBallPos = b2Vec2(100/PTM_RATIO, 100/PTM_RATIO);
    startPaddlePos = b2Vec2(winSize.width/2/PTM_RATIO, 50/PTM_RATIO);
    
    // Create contact listener
    contactListener = new MyContactListener();
    world->SetContactListener(contactListener);
}

- (void)initBall
{
    if(world == NULL) return;

    if(ball != nil) {
        [self removeChild:ball cleanup:YES];
    }

    // Create sprite
    ball = [CCSprite spriteWithFile:@"Ball.png" rect:CGRectMake(0, 0, 52, 52)];
    ball.position = ccp(100, 100);
    ball.tag = TAG_BALL;
    [self addChild:ball];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(startBallPos.x, startPaddlePos.y);
    ballBodyDef.userData = ball;
    ballBody = world->CreateBody(&ballBodyDef);
    
    // Create circle shape
    b2CircleShape circle;
    circle.m_radius = ball.contentSize.width/2/PTM_RATIO;
    
    // Create shape definition and add to body
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.0f;
    ballShapeDef.friction = 0.0f;
    ballShapeDef.restitution = 1.0f;
    ballFixture = ballBody->CreateFixture(&ballShapeDef);
    
    b2Vec2 force = b2Vec2(10, 10);
    ballBody->ApplyLinearImpulse(force, ballBodyDef.position);
}

- (void)initPaddle
{
    if(world == NULL) return;

    if(paddle != nil) {
        [self removeChild:paddle cleanup:YES];
    }

    // Create paddle
    paddle = [CCSprite spriteWithFile:@"Paddle.png"];
    paddle.position = ccp(winSize.width/2, 50);
    paddle.tag = TAG_PADDLE;
    [self addChild:paddle];
    
    // Create paddle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_dynamicBody;
    paddleBodyDef.position.Set(startPaddlePos.x, startPaddlePos.y);
    paddleBodyDef.userData = paddle;
    paddleBody = world->CreateBody(&paddleBodyDef);
    
    // Create paddle shape
    b2PolygonShape paddleShape;
    paddleShape.SetAsBox(paddle.contentSize.width/2/PTM_RATIO, paddle.contentSize.height/2/PTM_RATIO);
    
    // Create shape definition and add to body
    b2FixtureDef paddleShapeDef;
    paddleShapeDef.shape = &paddleShape;
    paddleShapeDef.density = 1.0f;
    paddleShapeDef.friction = 0.0f;
    paddleShapeDef.restitution = 1.0f;
    paddleFixture = paddleBody->CreateFixture(&paddleShapeDef);
    
    // Restrict paddle along the x axis
    b2PrismaticJointDef jointDef;
    b2Vec2 worldAxis(1.0f, 0.0f);
    jointDef.collideConnected = true;
    jointDef.Initialize(paddleBody, groundBody, paddleBody->GetWorldCenter(), worldAxis);
    world->CreateJoint(&jointDef);
    
}

- (void)initBlocks
{
    if(world == NULL) return;

    //NSLog(@"blocks count:%d", [blocks count]);
    if(blocks == nil) {
        blocks = [[NSMutableArray alloc] init];
    } else {
        for (CCSprite *sprite in blocks) {
            [self removeChild:sprite cleanup:YES];
        }
        
        [blocks removeAllObjects];
    }
    
    
    CCSprite *block = [CCSprite spriteWithFile:@"Block.png"];
    int blockWidth = block.contentSize.width;
    int blockHeight = block.contentSize.height;

    int xOffset = 5;
    int x = xOffset + blockWidth/2;
    int y = 250;
    for (int i = 0; i<4; i++) {
        CCSprite *sprite = [CCSprite spriteWithTexture:[block texture]];
        sprite.position = ccp(x, y);
        sprite.tag = TAG_BLOCK;
        [self addChild:sprite];
        [blocks addObject:sprite];
        
        // Create block body
        b2BodyDef blockBodyDef;
        blockBodyDef.type = b2_dynamicBody;
        blockBodyDef.position.Set(x/PTM_RATIO, y/PTM_RATIO);
        blockBodyDef.userData = sprite;
        b2Body *blockBody = world->CreateBody(&blockBodyDef);
        
        // Create block shape
        b2PolygonShape blockShape;
        blockShape.SetAsBox(blockWidth/2/PTM_RATIO, blockHeight/2/PTM_RATIO);
        
        // Create shape definition and add to body
        b2FixtureDef blockShapeDef;
        blockShapeDef.shape = &blockShape;
        blockShapeDef.density = 10.0f;
        blockShapeDef.friction = 0.0f;
        blockShapeDef.restitution = 0.1f;
        blockBody->CreateFixture(&blockShapeDef);
        
        x += xOffset + blockWidth;
    }
    
}

- (id)init
{
    if ((self = [super init])) {
        winSize = [CCDirector sharedDirector].winSize;
        [self setupGameMenu];
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"explode.wav"];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music.caf"];
        
        [self initWorld];
        [self initBall];
        [self initPaddle];
        [self initBlocks];

        lblGameOver = [CCLabelTTF labelWithString:@"" fontName:@"Verdana" fontSize:48.0];
        lblGameOver.position = ccp(winSize.width/2, winSize.height/2);
        lblGameOver.visible = NO;
        [self addChild:lblGameOver z:10];

        [self schedule:@selector(tick:)];
        
        self.isTouchEnabled = YES;
    }
    return self;
}

- (void)winGame
{
    [lblGameOver setString:@"You Win!"];
    lblGameOver.visible = true;
    lblGameOver.scale = 0.1;
    [lblGameOver runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    
    gameOverFlg = true;
}

- (void)gameOver
{
    [lblGameOver setString:@"You Loose :["];
    lblGameOver.visible = true;
    lblGameOver.scale = 0.1;
    [lblGameOver runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    
    gameOverFlg = true;
}

- (void)resetGame
{
    [self initWorld];
    [self initBall];
    [self initPaddle];
    [self initBlocks];
    
    lblGameOver.visible = false;
    gameOverFlg = false;
    pauseTime = 0;
}

- (void)tick:(ccTime)dt
{
    if(gameOverFlg) {
        pauseTime += dt;
        if (pauseTime > 5.0) {
            [self resetGame];
        }
        return;
    }

    bool blockFound  = false;
    
    world->Step(dt, 10, 10);
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        void *userData = b->GetUserData();
        if(userData != NULL) {
            CCSprite *sprite = (CCSprite *) userData;
            b2Vec2 pos = b->GetPosition();
            sprite.position = ccp(pos.x * PTM_RATIO, pos.y * PTM_RATIO);
            sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            
            if(sprite.tag == TAG_BALL) {
                static int maxSpeed = 10;
                b2Vec2 velocity = b->GetLinearVelocity();
                float32 speed = velocity.Length();
                if(speed > maxSpeed) {
                    b->SetLinearDamping(0.5);
                } else if(speed < maxSpeed) {
                    b->SetLinearDamping(0.0);
                }
            } else if(sprite.tag == TAG_BLOCK) {
                blockFound = true;
            }
        }
    }
    
    if(!blockFound) {
        [self winGame];
        return;
    }

    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for (pos = contactListener->_contacts.begin(); pos != contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        //NSLog(@"MyContact fixtureA: %@  fixtureB: %@", contact.fixtureA, contact.fixtureB);
        
        if((contact.fixtureA == bottomFixture && contact.fixtureB == ballFixture)
           || (contact.fixtureA == ballFixture && contact.fixtureB == bottomFixture)) {
            NSLog(@"Ball hit bottom!");
            [self gameOver];
        }
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        void *dataA = bodyA->GetUserData();
        void *dataB = bodyB->GetUserData();
        if(dataA != NULL && dataB != NULL) {
            CCSprite *spriteA = (CCSprite *) dataA;
            CCSprite *spriteB = (CCSprite *) dataB;
            
            if((spriteA.tag == TAG_BALL && spriteB.tag == TAG_BLOCK)
               || (spriteA.tag == TAG_BLOCK && spriteB.tag == TAG_BALL)) {
                b2Body *blockBody = (spriteA.tag == TAG_BLOCK) ? bodyA : bodyB;
                if(std::find(toDestroy.begin(), toDestroy.end(), blockBody) == toDestroy.end()) {
                    toDestroy.push_back(blockBody);
                }
            }
        }
    }
    
    if(toDestroy.size() > 0) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"explode.wav"];
        //[[SimpleAudioEngine sharedEngine] playEffect:@"blip.caf"];
        std::vector<b2Body *>::iterator pos2;
        for (pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
            b2Body *body = *pos2;
            void *userData = body->GetUserData();
            if(userData != NULL) {
                CCSprite *block = (CCSprite *)userData;
                [self removeChild:(CCSprite *)block cleanup:YES];
                CCParticleSystem * emitter = [CCParticleExplosion node];
                emitter.position = [block position];
                emitter.life = 0.1f;
                emitter.duration = 0.1f;
                emitter.lifeVar = 0.1f;
                emitter.totalParticles = 100;
                
                [self addChild:emitter];
            }
            world->DestroyBody(body);
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

    ballBody = NULL;
    ballFixture = NULL;

    paddleBody = NULL;
    paddleFixture = NULL;
    
    delete mouseJoint;
    delete contactListener;
    
    [blocks release];
    blocks = nil;

    [super dealloc];
}

@end
