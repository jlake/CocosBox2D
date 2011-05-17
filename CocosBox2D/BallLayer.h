//
//  BallLayer.h
//  CocosBox2D
//
//  Created by 欧 on 11/05/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface BallLayer : CCLayer {
    CGSize winSize;
    
	b2World *world;
    b2Body *body;
    CCSprite *ball;
}

+ (id)scene;

@end
