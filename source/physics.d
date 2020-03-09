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

module physics;

import serpent;

/**
 * VelocityComponent allows us define 2D velocity for sprites in our
 * game.
 */
final @serpentComponent struct VelocityComponent
{
    float xVelocity = 0.0f;
    float yVelocity = 0.0f;

    /**
     * Construct a new VelocityComponent with the given X + Y velocity
     */
    this(float xVelocity, float yVelocity) @safe @nogc nothrow
    {
        this.xVelocity = xVelocity;
        this.yVelocity = yVelocity;
    }
}

/**
 * Super simple collision with a box shape
 */
final @serpentComponent struct BoxCollider2DComponent
{
    box2f shape;

    this(box2f shape)
    {
        this.shape = shape;
    }
}

/**
 * PhysicsProcessor is very simple right now. Move things around the screen
 * when they have a velocity. Eventually we need to add collisions but we'll
 * do that after.
 */
final class PhysicsProcessor : Processor!ReadWrite
{

    /**
     * Initialise the processor and register required components
     */
    final override void bootstrap(View!ReadWrite view)
    {
        context.entity.tryRegisterComponent!BoxCollider2DComponent;
        context.entity.tryRegisterComponent!VelocityComponent;
    }

    /**
     * Perform updates for the current frame tick.
     */
    final override void run(View!ReadWrite view)
    {
        auto frameTime = context.frameTime();

        foreach (ent, transform, vel; view.withComponents!(TransformComponent, VelocityComponent))
        {
            transform.position.x += vel.xVelocity * frameTime;
            transform.position.y += vel.yVelocity * frameTime;
        }
    }
}
