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

module paddleGame.ai;

import serpent;

import paddleGame.ball;
import serpent.physics2d;
import std.math : abs;

/**
 * AI can follow an edge
 */
final enum AIEdge
{
    None = 0,
    Left,
    Right,
}

/**
 * AI Component is added to 'enemy' paddles
 */
final @serpentComponent struct AIComponent
{
    AIEdge edge;
}

/**
 * AI Processor manages the response of each 'enemy' paddle
 * currently in play.
 */
final class AIProcessor : Processor!ReadWrite
{

private:

    /* Prevent jitter physics */
    const int zoneTolerance = 5;
    const float paddleSpeed = 0.3f;

public:

    /**
     * Register the AI Component with the system
     */
    final override void bootstrap(View!ReadWrite)
    {
        context.entity.tryRegisterComponent!AIComponent;
        context.entity.tryRegisterComponent!BallComponent;
    }

    final void moveEntityToPosition(PhysicsComponent* physics,
            TransformComponent* transform, int targetY)
    {
        int positionY = cast(int) transform.position.y;
        auto diff = abs(positionY - targetY);

        if (diff <= zoneTolerance)
        {
            physics.body.velocity = vec2f(0.0f, 0.0f);
        }
        else if (targetY < positionY)
        {
            physics.body.velocity = vec2f(0.0f, -paddleSpeed);
        }
        else
        {
            physics.body.velocity = vec2f(0.0f, paddleSpeed);
        }

    }

    final void returnPaddlesToHome(View!ReadWrite view)
    {
        foreach (entity, enemy, physics, transform, sprite; view.withComponents!(AIComponent,
                PhysicsComponent, TransformComponent, SpriteComponent))
        {
            if (enemy.edge == AIEdge.None)
            {
                continue;
            }
            int targetY = cast(int)(
                    (context.display.logicalHeight / 2.0f) - (sprite.texture.height / 2.0f));
            moveEntityToPosition(physics, transform, targetY);
        }
    }
    /**
     * Manage AI response
     */
    final override void run(View!ReadWrite view)
    {
        auto balls = view.withComponents!(BallComponent, TransformComponent, PhysicsComponent);
        if (balls.empty())
        {
            returnPaddlesToHome(view);
            return;
        }

        /* Eventually we'll support more than one ball */
        auto primaryBall = balls.front();
        auto ballTransform = primaryBall[2];
        auto ballPhysics = primaryBall[3];

        foreach (entity, enemy, transform, physics, sprite; view.withComponents!(AIComponent,
                TransformComponent, PhysicsComponent, SpriteComponent))
        {
            if (enemy.edge == AIEdge.None)
            {
                continue;
            }

            int targetY = cast(int)(ballTransform.position.y - (sprite.texture.height / 2.0f));
            int positionY = cast(int) transform.position.y;

            auto topBounds = 32;
            auto bottomBounds = cast(int)(context.display.logicalHeight - 32.0f);
            if (targetY <= topBounds)
            {
                targetY = topBounds;
            }
            else if (targetY + sprite.texture.height >= bottomBounds)
            {
                targetY = cast(int)(bottomBounds - sprite.texture.height);
            }

            /* Ball heading away from us? TODO: Work out our potential position */
            if ((enemy.edge == AIEdge.Right && ballPhysics.body.velocity.x < 0.0f)
                    || (enemy.edge == AIEdge.Left && ballPhysics.body.velocity.x > 0.0f))
            {
                targetY = cast(int)((context.display.logicalHeight / 2.0f) - (
                        sprite.texture.height / 2.0f));
            }

            moveEntityToPosition(physics, transform, targetY);
        }
    }
}
