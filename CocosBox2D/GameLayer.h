//
//  GameLayer.h
//  CocosBox2D
//
//  Created by 欧 on 11/05/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"

@interface GameLayer : CCLayer {
    CGSize winSize;

	b2World *world;
    b2Body *groundBody;
    b2Fixture *bottomFixture;
    
    CCSprite *ball;
    b2Body *ballBody;
    b2Fixture *ballFixture;

    CCSprite *paddle;
    b2Body *paddleBody;
    b2Fixture *paddleFixture;
    
    b2Vec2 startBallPos;
    b2Vec2 startPaddlePos;
    
    b2MouseJoint *mouseJoint;
    
    MyContactListener *contactListener;

    BOOL gameOverFlg;
    ccTime pauseTime;
    CCLabelTTF *lblGameOver;
    
    NSMutableArray *blocks;
}

+ (id)scene;

@end
