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

module ai;

import serpent;

/**
 * A Paddle can either go vertically or horizontally, not both
 */
final enum AIConstraint
{
    Vertical = 0,
    Horizontal,
}

/**
 * AI Component is added to 'enemy' paddles
 */
final @serpentComponent struct AIComponent
{
    AIConstraint constraint;
}

/**
 * AI Processor manages the response of each 'enemy' paddle
 * currently in play.
 */
final class AIProcessor : Processor!ReadWrite
{

    /**
     * Register the AI Component with the system
     */
    final override void bootstrap(View!ReadWrite)
    {
        context.entity.tryRegisterComponent!AIComponent;
    }

    /**
     * Manage AI response
     */
    final override void run(View!ReadWrite view)
    {
        foreach (entity, enemy, transform; view.withComponents!(AIComponent, TransformComponent))
        {
        }
    }
}
