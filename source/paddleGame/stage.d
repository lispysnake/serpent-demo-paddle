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

module paddleGame.stage;

import paddleGame.ai;
import paddleGame.ball;

import gfm.math;
import serpent;
import std.path : buildPath;
import std.string : format;

import serpent.physics2d;

public import std.signals;

final enum PaddleOwner
{
    PlayerOne = 0,
    PlayerTwo,
    ObstacleOne,
    ObstacleTwo,
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
    Texture ballTextureAlt;
    Texture paddleTextureTeam1;
    Texture paddleTextureTeam2;
    Texture paddleTextureObstacle;
    Texture texSplash;

    Texture[10] numeralTexture;

    Texture borderTexture;
    Texture borderTexture2;

    float _width = 0;
    float _height = 0;

    AbstractWorld world;
    const float obstacleSpeed = 0.2f;
    string assetBasePath = "";

public:

    @disable this();

    /**
     * Emitted with the barrier ID, and the ball ID
     */
    mixin Signal!(EntityID, EntityID) scoreEvent;

    /**
     * Let main context know an impact event occured
     */
    mixin Signal!(EntityID, EntityID) impactEvent;

    mixin Signal!(EntityID) invertObstacleEvent;

    /**
     * Construct a new Stage with the given width and height
     */
    this(AbstractWorld world, string assetBasePath, float width, float height)
    {
        this._width = width;
        this._height = height;
        this.assetBasePath = assetBasePath;

        ballTexture = new Texture(buildPath(assetBasePath, "ball.png"), TextureFilter.Linear);
        ballTextureAlt = new Texture(buildPath(assetBasePath, "ballAlt.png"), TextureFilter.Linear);

        paddleTextureTeam1 = new Texture(buildPath(assetBasePath,
                "paddleBlue.png"), TextureFilter.Linear);
        paddleTextureTeam2 = new Texture(buildPath(assetBasePath,
                "paddleRed.png"), TextureFilter.Linear);

        paddleTextureObstacle = new Texture(buildPath(assetBasePath,
                "paddleInert.png"), TextureFilter.Linear);

        texSplash = new Texture(buildPath(assetBasePath, "paddle.png"), TextureFilter.Linear);

        foreach (i; 0 .. 10)
        {
            numeralTexture[i] = new Texture(buildPath(assetBasePath,
                    "numeral%d.png".format(i)), TextureFilter.Linear);
        }

        borderTexture = new Texture(buildPath(assetBasePath, "wall.png"), TextureFilter.Linear);
        borderTexture2 = new Texture(buildPath(assetBasePath, "wall2.png"), TextureFilter.Linear);
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
     * Spawn the splash screen
     */
    final EntityID spawnSplash(View!ReadWrite view) @system
    {
        auto ent = view.createEntity();
        auto sprite = SpriteComponent();
        sprite.texture = texSplash;
        view.addComponent(ent, sprite);
        auto trans = TransformComponent();
        trans.position.z = 0.3f;
        view.addComponent(ent, trans);
        auto col = ColorComponent();
        col.rgba = vec4f(1.0f, 1.0f, 1.0f, 1.0f);
        view.addComponent(ent, col);
        return ent;
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
        import std.random : uniform;

        if (uniform(0, 2) >= 1)
        {
            spriteBall.texture = ballTexture;
        }
        else
        {
            spriteBall.texture = ballTextureAlt;
        }

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
        physShape.mass = 100.0f;
        physShape.elasticity = 1.0f;
        physShape.friction = 0.0f;
        physBody.velocity = vec2f(-0.45f, -0.1f);
        physBody.minVelocity = vec2f(0.4f, 0.1f);
        physBody.maxVelocity = vec2f(0.85f, 0.85f);
        physBody.add(physShape);

        auto comp = BallComponent();
        comp.type = BallType.Standard;
        view.addComponent(entBall, comp);

        view.addComponent(entBall, physBall);
    }

    /**
     * Add circle shape sensors to the body.
     *
     * This helps us detect when we hit on the top or bottom so we know
     * to change direction of the obstacle paddle
     */
    final void addObstacleSensors(SpriteComponent* sprite, PhysicsComponent* physics)
    {
        /* Add top sensor */
        auto circleTop = new CircleShape(sprite.texture.width / 2.0f, vec2f(0.0f, 0.0f));
        physics.body.add(circleTop);
        circleTop.sensor = true;

        physics.body.sensorActivated.connect(&onObstacleSensor);

        auto circleBottom = new CircleShape(sprite.texture.width / 2.0f,
                vec2f(0.0f, sprite.texture.height - (sprite.texture.width / 2.0f)));
        physics.body.add(circleBottom);
        circleBottom.sensor = true;
    }

    /**
     * If the obstacle hits a sensor, invert the velocity.
     */
    final void onObstacleSensor(Shape shape1, Shape shape2)
    {
        auto seg = cast(SegmentShape) shape2;
        if (seg is null)
        {
            return;
        }
        invertObstacleEvent.emit(shape1.chipBody.entity);
    }

    /**
     * Spawn a paddle and handle all the boilerplate.
     */
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
        case PaddleOwner.ObstacleOne:
        case PaddleOwner.ObstacleTwo:
            spritePaddle.texture = paddleTextureObstacle;
        }

        /* Transform */
        auto transPaddle = TransformComponent();
        transPaddle.position.y = (height / 2.0f) - (spritePaddle.texture.height / 2.0f);

        final switch (owner)
        {
        case PaddleOwner.PlayerOne:
            transPaddle.position.x = 25.0f;
            break;
        case PaddleOwner.PlayerTwo:
            transPaddle.position.x = width - spritePaddle.texture.width - 25.0f;
            break;
        case PaddleOwner.ObstacleOne:
            transPaddle.position.x = (width / 2.0f) - (spritePaddle.texture.width / 2.0f) - 32.0f;
            break;
        case PaddleOwner.ObstacleTwo:
            transPaddle.position.x = (width / 2.0f) - (spritePaddle.texture.width / 2.0f) + 32.0f;
            break;
        }

        auto physPaddle = PhysicsComponent();
        auto physBody = new KinematicBody();
        physBody.collision.connect(&ballHitted);

        physPaddle.body = physBody;

        auto physShape = new BoxShape(spritePaddle.texture.width, spritePaddle.texture.height);
        physShape.elasticity = 1.0f;
        physShape.friction = 0.0f;
        physBody.add(physShape);

        /**
         * Mark this as an AI paddle on the correct edge
         */
        if (type == PaddleType.Computer)
        {
            auto comp = AIComponent();
            final switch (owner)
            {
            case PaddleOwner.PlayerOne:
                comp.edge = AIEdge.Left;
                break;
            case PaddleOwner.PlayerTwo:
                comp.edge = AIEdge.Right;
                break;
            case PaddleOwner.ObstacleOne:
                physBody.velocity = vec2f(0.0f, obstacleSpeed);
                addObstacleSensors(&spritePaddle, &physPaddle);
                comp.edge = AIEdge.None;
                break;
            case PaddleOwner.ObstacleTwo:
                physBody.velocity = vec2f(0.0f, -obstacleSpeed);
                addObstacleSensors(&spritePaddle, &physPaddle);
                comp.edge = AIEdge.None;
                break;
            }
            view.addComponent(entPaddle, comp);
        }

        view.addComponent(entPaddle, spritePaddle);
        view.addComponent(entPaddle, transPaddle);
        view.addComponent(entPaddle, physPaddle);

        return entPaddle;
    }

    /**
     * Create a new invisible barrier used for top/bottom collisions.
     * Left + right are used as sensors only
     */
    final EntityID createBarrier(View!ReadWrite view, vec2f pointA, vec2f pointB,
            bool sensorNode = false)
    {
        auto entityID = view.createEntity();
        auto trans = TransformComponent();
        trans.position.x = pointA.x;
        trans.position.y = pointA.y;

        pointB.x -= pointA.x;
        pointB.y -= pointA.y;
        pointA.x = 0.0f;
        pointA.y = 0.0f;

        auto body = new StaticBody();
        auto shape = new SegmentShape(pointA, pointB, 26.0f);
        shape.elasticity = 1.0f;
        shape.friction = 1.0f;
        shape.mass = 300.0f;
        shape.sensor = sensorNode;
        body.add(shape);
        auto phys = PhysicsComponent();
        phys.body = body;

        if (sensorNode)
        {
            body.sensorActivated.connect(&barrierActivated);
        }
        else
        {
            body.collision.connect(&ballHitted);
        }

        view.addComponent(entityID, phys);
        view.addComponent(entityID, trans);

        return entityID;
    }

    /**
     * Dispatch the event that a ball was used to score
     */
    final void barrierActivated(Shape ourShape, Shape theirShape)
    {
        scoreEvent.emit(ourShape.chipBody.entity, theirShape.chipBody.entity);
    }

    final void ballHitted(Shape ourShape, Shape theirShape)
    {
        impactEvent.emit(ourShape.chipBody.entity, theirShape.chipBody.entity);
    }

    /**
     * Spawn walls
     */
    final EntityID[] spawnWalls(View!ReadWrite view)
    {
        /* Ensure pixel perfect bounds with extremely thick (26px) segment barriers */
        EntityID[] ret = [
            createBarrier(view, vec2f(0.0f, borderTexture.height - 26.0f - 13.0f),
                    vec2f(width, borderTexture.height - 26.0f - 13.0f)), /* top */
            createBarrier(view, vec2f(0.0f,
                    height - borderTexture.height + 13.0f), vec2f(width,
                    height - borderTexture.height + 13.0f)), /* bottom */
            createBarrier(view, vec2f(width + 13.0f,
                    0.0f), vec2f(width + 13.0f, height), true), /* right */
            createBarrier(view,
                    vec2f(0.0f - 26.0f - 13.0f, 0.0f), vec2f(0.0f - 26.0f - 13.0f, height), true), /* left */
        ];

        return ret;
    }

    /**
     * Return the scoreboard entity
     */
    final EntityID spawnScore(View!ReadWrite view, PaddleOwner owner)
    {
        auto entityID = view.createEntity();
        auto trans = TransformComponent();
        auto sprite = SpriteComponent();

        trans.position.y = 48.0f;
        trans.position.x = owner == PaddleOwner.PlayerOne ? 32.0f : width - 64.0f;
        trans.scale.x = 2.0f;
        trans.scale.y = 2.0f;
        trans.position.z = 0.4f;

        sprite.texture = numeralTexture[0];

        view.addComponent(entityID, trans);
        view.addComponent(entityID, sprite);

        auto col = ColorComponent();
        if (owner == PaddleOwner.PlayerOne)
        {
            col.rgba = vec4f(0.3f, 0.8f, 0.3f, 1.0f);

        }
        else
        {
            col.rgba = vec4f(0.8f, 0.3f, 0.3, 1.0f);
        }

        /* See-through score at first */
        col.rgba.a = 0.0f;
        view.addComponent(entityID, col);
        return entityID;
    }

    /**
     * Spawn the countdown timer
     */
    final EntityID spawnCountdown(View!ReadWrite view)
    {
        auto entityID = view.createEntity();
        auto trans = TransformComponent();
        auto sprite = SpriteComponent();
        sprite.texture = numeralTexture[3];

        trans.position.y = 64.0f;
        trans.position.x = (width / 2.0f) - ((sprite.texture.width / 2.0f) * 3.0f);
        trans.scale.x = 3.0f;
        trans.scale.y = 3.0f;
        trans.position.z = 0.4f;

        auto col = ColorComponent();
        col.rgba = vec4f(1.0f, 1.0f, 1.0f, 0.0f);

        view.addComponent(entityID, col);
        view.addComponent(entityID, trans);
        view.addComponent(entityID, sprite);

        return entityID;
    }

    /**
     * Update the score numeral
     */
    final void setScore(View!ReadWrite view, EntityID id, int score)
    {
        auto sprite = view.data!SpriteComponent(id);
        sprite.texture = numeralTexture[score < 9 ? score : 9];
    }

    /**
     * Spawn a pretty brick border
     */
    final void spawnBorder(View!ReadWrite view)
    {
        auto tileWidth = width / borderTexture.width;
        foreach (i; 0 .. tileWidth)
        {
            {
                auto ent = view.createEntity();
                auto sprite = SpriteComponent();
                sprite.texture = borderTexture;
                auto trans = TransformComponent();
                trans.position.x = i * borderTexture.width;
                trans.position.y = 0;

                view.addComponent(ent, sprite);
                view.addComponent(ent, trans);
            }

            {
                auto ent = view.createEntity();
                auto sprite = SpriteComponent();
                sprite.texture = borderTexture2;
                auto trans = TransformComponent();
                trans.position.x = i * borderTexture2.width;
                trans.position.y = height - borderTexture2.height;

                view.addComponent(ent, sprite);
                view.addComponent(ent, trans);
            }
        }
    }
}
