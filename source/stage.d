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

import ai;
import ball;

import gfm.math;
import serpent;
import std.path : buildPath;

import serpent.physics2d;

final enum PaddleOwner
{
    PlayerOne = 0,
    PlayerTwo,
}

final enum PaddleType
{
    Human = 0,
    Computer
}

/**
 * The Stage is basically our game layout. It is divided as such that
 * it has bounding boxes for collisions.
 */

final class Stage
{

private:

    Texture ballTexture;
    Texture paddleTextureTeam1;
    Texture paddleTextureTeam2;

    float _width = 0;
    float _height = 0;

    AbstractWorld world;

public:

    @disable this();

    /**
     * Construct a new Stage with the given width and height
     */
    this(AbstractWorld world, float width, float height)
    {
        this._width = width;
        this._height = height;

        ballTexture = new Texture(buildPath("assets", "ball.png"), TextureFilter.Linear);

        paddleTextureTeam1 = new Texture(buildPath("assets", "paddleBlue.png"),
                TextureFilter.Linear);
        paddleTextureTeam2 = new Texture(buildPath("assets", "paddleRed.png"), TextureFilter.Linear);
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

        view.addComponent(entBall, spriteBall);
        view.addComponent(entBall, transBall);

        auto physBall = PhysicsComponent();
        auto physBody = new DynamicBody();
        physBall.body = physBody;
        auto physShape = new CircleShape(ballTexture.width / 2.0, vec2f(0.0f, 0.0f));
        physShape.mass = 0.1f;
        physShape.elasticity = 1.0f;
        physShape.friction = 0.0f;
        physBody.velocity = vec2f(-0.3f, -0.1f);
        physBody.add(physShape);

        auto comp = BallComponent();
        comp.type = BallType.Standard;
        view.addComponent(entBall, comp);

        view.addComponent(entBall, physBall);
    }

    final EntityID spawnPaddle(View!ReadWrite view, PaddleOwner owner, PaddleType type)
    {
        /* CPU paddle */
        auto entPaddle = view.createEntity();

        /* Sprite */
        auto spritePaddle = SpriteComponent();
        final switch (owner)
        {
        case PaddleOwner.PlayerOne:
            spritePaddle.texture = paddleTextureTeam1;
            break;
        case PaddleOwner.PlayerTwo:
            spritePaddle.texture = paddleTextureTeam2;
            break;
        }

        /* Transform */
        auto transPaddle = TransformComponent();
        transPaddle.position.y = (height / 2.0f) - (spritePaddle.texture.height / 2.0f);

        if (owner == PaddleOwner.PlayerOne)
        {
            transPaddle.position.x = 25.0f;
        }
        else
        {
            transPaddle.position.x = width - spritePaddle.texture.width - 25.0f;
        }

        view.addComponent(entPaddle, spritePaddle);
        view.addComponent(entPaddle, transPaddle);

        auto physPaddle = PhysicsComponent();
        auto physBody = new KinematicBody();
        physPaddle.body = physBody;

        auto physShape = new BoxShape(spritePaddle.texture.width, spritePaddle.texture.height);
        physShape.elasticity = 1.0f;
        physShape.friction = 0.0f;
        physBody.add(physShape);

        view.addComponent(entPaddle, physPaddle);

        /**
         * Mark this as an AI paddle on the correct edge
         */
        if (type == PaddleType.Computer)
        {
            auto comp = AIComponent();
            comp.constraint = AIConstraint.Vertical;
            final switch (owner)
            {
            case PaddleOwner.PlayerOne:
                comp.edge = AIEdge.Left;
                break;
            case PaddleOwner.PlayerTwo:
                comp.edge = AIEdge.Right;
                break;
            }
            view.addComponent(entPaddle, comp);
        }

        return entPaddle;
    }

    final EntityID createWall(View!ReadWrite view, box2f position)
    {
        auto entityID = view.createEntity();
        auto trans = TransformComponent();
        trans.position.x = position.min.x;
        trans.position.y = position.min.y;
        auto body = new StaticBody();
        auto width = position.max.x - position.min.x;
        auto height = position.max.y - position.min.y;
        auto shape = new BoxShape(width, height, 3.0f);
        shape.elasticity = 1.0f;
        shape.friction = 1.0f;
        shape.mass = 1.0f;
        shape.density = 1.0f;
        body.add(shape);
        auto phys = PhysicsComponent();
        phys.body = body;

        view.addComponent(entityID, phys);
        view.addComponent(entityID, trans);

        return entityID;
    }

    /**
     * Spawn walls
     */
    final EntityID[] spawnWalls(View!ReadWrite view)
    {
        EntityID[] ret = [
            createWall(view, rectanglef(0.0f, 0.0f, 1.0f, 768.0f)), /* left */
            createWall(view, rectanglef(1366.0f - 1.0f,
                    0.0f, 1.0f, 768.0f)), /* right */
            createWall(view, rectanglef(0.0f, -30.0f, 1366.0f,
                    30.0f)), /* top */
            createWall(view, rectanglef(0.0f, 768.0f - 30.0f, 1366.0f, 30.0f)), /* bottom */
        ];

        return ret;
    }
}
