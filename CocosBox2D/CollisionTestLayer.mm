//
//  CollisionTestLayer.m
//  CocosBox2D
//
//  Created by 欧 on 11/05/18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CollisionTestLayer.h"
#import "MenuLayer.h"
#import "SimpleAudioEngine.h"

#define PTM_RATIO 32.0
#define TAG_CAT 1
#define TAG_CAR 2

@implementation CollisionTestLayer

+ (id)scene
{
    CCScene *scene = [CCScene node];
    CollisionTestLayer *layer = [CollisionTestLayer node];
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


- (void)initWorld
{
    if(world != NULL) {
        delete world;
    }
    
    // Create world
    b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
    bool doSleep = false;
    world = new b2World(gravity, doSleep);

    // Create contact listener
    contactListener = new MyContactListener();
    world->SetContactListener(contactListener);

    // Enable debug draw
    m_debugDraw = new GLESDebugDraw( PTM_RATIO );
    world->SetDebugDraw(m_debugDraw);
    
    uint32 flags = 0;
    flags += b2DebugDraw::e_shapeBit;
    //flags += b2DebugDraw::e_jointBit;
    //flags += b2DebugDraw::e_aabbBit;
    //flags += b2DebugDraw::e_pairBit;
    //flags += b2DebugDraw::e_centerOfMassBit;
    m_debugDraw->SetFlags(flags);		

}

- (void)addBoxBodyForSprite:(CCSprite *)sprite
{
    if(world == NULL) return;
    
    // Create sprite body
    b2BodyDef spriteBodyDef;
    spriteBodyDef.type = b2_dynamicBody;
    spriteBodyDef.position.Set(sprite.position.x/PTM_RATIO, sprite.position.y/PTM_RATIO);
    spriteBodyDef.userData = sprite;
    b2Body *spriteBody = world->CreateBody(&spriteBodyDef);
    
    // Create sprite shape
    b2PolygonShape spriteShape;
    //spriteShape.SetAsBox(sprite.contentSize.width/2/PTM_RATIO, sprite.contentSize.height/2/PTM_RATIO);
    if (sprite.tag == TAG_CAT) {
        int num = 6;
        b2Vec2 verts[] = {b2Vec2(4.5f / PTM_RATIO, -17.7f / PTM_RATIO),
            b2Vec2(20.5f / PTM_RATIO, 7.2f / PTM_RATIO),
            b2Vec2(22.8f / PTM_RATIO, 29.5f / PTM_RATIO),
            b2Vec2(-24.7f / PTM_RATIO, 31.0f / PTM_RATIO),
            b2Vec2(-20.2f / PTM_RATIO, 4.7f / PTM_RATIO),
            b2Vec2(-11.7f / PTM_RATIO, -17.5f / PTM_RATIO)};
        spriteShape.Set(verts, num);
    } else if (sprite.tag == TAG_CAR) {
        // Do the same thing as the above, but use the car data this time
        int num = 7;
        b2Vec2 verts[] = {b2Vec2(-11.8f / PTM_RATIO, -24.5f / PTM_RATIO),
            b2Vec2(11.7f / PTM_RATIO, -24.0f / PTM_RATIO),
            b2Vec2(29.2f / PTM_RATIO, -14.0f / PTM_RATIO),
            b2Vec2(28.7f / PTM_RATIO, -0.7f / PTM_RATIO),
            b2Vec2(8.0f / PTM_RATIO, 18.2f / PTM_RATIO),
            b2Vec2(-29.0f / PTM_RATIO, 18.7f / PTM_RATIO),
            b2Vec2(-26.3f / PTM_RATIO, -12.2f / PTM_RATIO)};
        spriteShape.Set(verts, num);
    }
    
    // Create shape definition and add to body
    b2FixtureDef spriteShapeDef;
    spriteShapeDef.shape = &spriteShape;
    spriteShapeDef.density = 10.0;
    spriteShapeDef.isSensor = true;
    //spriteShapeDef.friction = 0.0f;
    //spriteShapeDef.restitution = 0.1f;
    spriteBody->CreateFixture(&spriteShapeDef);
}


- (void)spawnCar
{
    CCSprite *car = [CCSprite spriteWithSpriteFrameName:@"car.png"];
    car.position = ccp(100, 100);
    car.tag = TAG_CAR;
    
    [car runAction:[CCRepeatForever actionWithAction:
                    [CCSequence actions:
                     [CCMoveTo actionWithDuration:1.0 position:ccp(320, 80)],
                     [CCMoveTo actionWithDuration:1.0 position:ccp(240, 240)],
                     [CCMoveTo actionWithDuration:1.0 position:ccp(80, 80)],
                     nil]]];

    [self addBoxBodyForSprite:car];
    [spriteSheet addChild:car z:0 tag:TAG_CAR];
}

- (void)spawnCat
{
    CCSprite *cat = [CCSprite spriteWithSpriteFrameName:@"cat.png"];
    
    int startX = winSize.width + (cat.contentSize.width/2);
    int endX = -(cat.contentSize.width/2);

    int minY = cat.contentSize.height/2;
    int maxY = winSize.height - (cat.contentSize.height/2);
    int rangeY = maxY - minY;
    int actualY = arc4random() % rangeY;
    
    CGPoint startPos = ccp(startX, actualY);
    CGPoint endPos = ccp(endX, actualY);
    
    cat.position = startPos;
    cat.tag = TAG_CAT;
    
    [cat runAction:[CCSequence actions:
                    [CCMoveTo actionWithDuration:1.0 position:endPos],
                    [CCCallFuncN actionWithTarget:self selector:@selector(spriteDone:)],
                     nil]];
    
    [self addBoxBodyForSprite:cat];
    [spriteSheet addChild:cat z:0 tag:TAG_CAT];
}

- (void)spriteDone:(id)sender
{
    CCSprite *sprite = (CCSprite *)sender;
    
    b2Body *spriteBody = NULL;
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        void *userData = b->GetUserData();
        if(userData != NULL) {
            CCSprite *curSprite = (CCSprite *) userData;
            if(sprite == curSprite) {
                spriteBody = b;
                break;
            }
        }
    }
    if(spriteBody != NULL) {
        world->DestroyBody(spriteBody);
    }
    
    [spriteSheet removeChild:sprite cleanup:YES];
}

- (id)init
{
    if ((self = [super init])) {
        winSize = [CCDirector sharedDirector].winSize;
        [self setupGameMenu];
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hahaha.caf"];

        // Create sprite sheet and cache
        //spriteSheet = [[CCSpriteBatchNode batchNodeWithFile:@"ccsprites.png"] retain];
        spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"ccsprites.png"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ccsprites.plist"];
        [self addChild:spriteSheet];
        
        [self initWorld];
        [self spawnCar];
         
        [self schedule:@selector(secondUpdate:) interval:1.0];
        [self schedule:@selector(tick:)];
    }
    return self;
}

-(void) draw
{
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)secondUpdate:(ccTime)dt
{
    [self spawnCat];
}

- (void)tick:(ccTime)dt
{
    world->Step(dt, 10, 10);
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        void *userData = b->GetUserData();
        if(userData != NULL) {
            CCSprite *sprite = (CCSprite *) userData;
            b2Vec2 b2Position = b2Vec2(sprite.position.x/PTM_RATIO, sprite.position.y/PTM_RATIO);
            float32 b2Angle = -1 * CC_DEGREES_TO_RADIANS(sprite.rotation);
            b->SetTransform(b2Position, b2Angle);
        }
    }

    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for (pos = contactListener->_contacts.begin(); pos != contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        void *dataA = bodyA->GetUserData();
        void *dataB = bodyB->GetUserData();
        if(dataA != NULL && dataB != NULL) {
            CCSprite *spriteA = (CCSprite *) dataA;
            CCSprite *spriteB = (CCSprite *) dataB;
            
            if((spriteA.tag == TAG_CAT && spriteB.tag == TAG_CAR)
               || (spriteA.tag == TAG_CAR && spriteB.tag == TAG_CAT)) {
                toDestroy.push_back((spriteA.tag == TAG_CAT) ? bodyA : bodyB);
            }
        }
    }
    
    if(toDestroy.size() > 0) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"hahaha.caf"];
        std::vector<b2Body *>::iterator pos2;
        for (pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
            b2Body *body = *pos2;
            void *userData = body->GetUserData();
            if(userData != NULL) {
                CCSprite *sprite = (CCSprite *)userData;

                CCParticleSystem *emitter = [CCParticleExplosion node];
                emitter.position = [sprite position];
                emitter.life = 0.1f;
                emitter.duration = 0.1f;
                emitter.lifeVar = 0.1f;
                emitter.totalParticles = 50;
                [self addChild:emitter];
                
                [self removeChild:(CCSprite *)sprite cleanup:YES];
                
            }
            world->DestroyBody(body);
        }
    }

}

- (void)dealloc {
    delete world;
    world = NULL;
    
    delete m_debugDraw;
    delete contactListener;
    
    [super dealloc];
}

@end
