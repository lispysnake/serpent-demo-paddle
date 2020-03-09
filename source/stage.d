/*
 * This file is part of serpent.
 *
 * Copyright © 2019-2020 Lispy Snake, Ltd.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module stage;

import gfm.math;
import serpent;

import physics;

/**
 * The Stage is basically our game layout. It is divided as such that
 * it has bounding boxes for collisions.
 */

final class Stage
{

private:

    Texture ballTexture;
    Texture paddleTextureTeam1;
    ;
    Texture paddleTextureTeam2;

    box2f worldTop;
    box2f worldLeft;
    box2f worldRight;
    box2f worldBottom;
    float _width = 0;
    float _height = 0;
    float meterSize;

public:

    @disable this();

    /**
     * Construct a new Stage with the given width and height
     */
    this(float width, float height)
    {
        this._width = width;
        this._height = height;

        /* 10 meters wide */
        meterSize = width / 10.0f;

        ballTexture = new Texture("assets/ball.png");

        paddleTextureTeam1 = new Texture("assets/paddle2.png");
        paddleTextureTeam2 = new Texture("assets/paddle.png");
    }

    /**
     * Return stage width
     */
    pure final const @property float width() @safe @nogc nothrow
    {
        return _width;
    }

    /**
     * Return stage height
     */
    pure final const @property float height() @safe @nogc nothrow
    {
        return _height;
    }

    /**
     * Spawn a new ball into play
     */
    final void spawnBall(View!ReadWrite view) @system
    {
        /* ball */
        auto entBall = view.createEntity();

        /* Set up sprite texture */
        auto spriteBall = SpriteComponent();
        spriteBall.texture = ballTexture;

        /* Set up transform (position) */
        auto transBall = TransformComponent();
        transBall.position.y = (height / 2.0f) - (ballTexture.height / 2.0f);
        transBall.position.x = (width / 2.0f) - (ballTexture.width / 2.0f);

        /* Set up basic physics */
        auto ballSpeed = (meterSize * -1.5f) / 1000.0f;
        auto velBall = VelocityComponent(ballSpeed, 0.0f);
        auto boxBall = BoxCollider2DComponent(rectanglef(0.0f, 0.0f,
                ballTexture.width, ballTexture.height));

        view.addComponent(entBall, spriteBall);
        view.addComponent(entBall, transBall);
        view.addComponent(entBall, velBall);
        view.addComponent(entBall, boxBall);
    }

    final void spawnPaddle(View!ReadWrite view, bool leftEdge)
    {
        /* CPU paddle */
        auto entPaddle = view.createEntity();

        /* Sprite */
        auto spritePaddle = SpriteComponent();
        spritePaddle.texture = leftEdge ? paddleTextureTeam1 : paddleTextureTeam2;

        /* Transform */
        auto transPaddle = TransformComponent();
        if (leftEdge)
        {
            transPaddle.position.x = 25.0f;
        }
        else
        {
            transPaddle.position.x = width - spritePaddle.texture.width - 25.0f;
        }

        transPaddle.position.y = (height / 2.0f) - (spritePaddle.texture.height / 2.0f);

        view.addComponent(entPaddle, spritePaddle);
        view.addComponent(entPaddle, transPaddle);

    }
}
