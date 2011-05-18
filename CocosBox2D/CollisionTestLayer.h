//
//  CollisionTestLayer.h
//  CocosBox2D
//
//  Created by 欧 on 11/05/18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "MyContactListener.h"

@interface CollisionTestLayer : CCLayer {
    CGSize winSize;

    CCSpriteBatchNode *spriteSheet;
    
	b2World *world;
    b2Body *groundBody;
    b2Fixture *bottomFixture;

    CCSprite *ball;
    b2Body *ballBody;
    b2Fixture *ballFixture;
    
    MyContactListener *contactListener;
    
    GLESDebugDraw *m_debugDraw;
}

+ (id)scene;

@end
