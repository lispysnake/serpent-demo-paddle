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

module physics2D.world;

import chipmunk;
import physics2D.physicsbody;

/**
 * The World class is reponsible for the integration of physics into the
 * game world. As such, physics data must be created *through* the World
 * to ensure it is correctly tracked.
 */
final class World2D
{

private:

    cpSpace* _space = null;

public:

    /**
     * Construct a new World2D instance.
     */
    this()
    {
        _space = cpSpaceNew();
    }

    /**
     * Destroy the World2D instance.
     */
    ~this()
    {
        cpSpaceFree(_space);
        _space = null;
    }

    /**
     * Create a new Physics2DBody parented to this world
     */
    Physics2DBody* createDynamicBody(double mass, double moment)
    {
        cpBody* bod = cpBodyNew(mass, moment);
        import std.stdio;

        if (bod is null)
        {
            writeln("?????");
        }
        cpSpaceAddBody(_space, bod);

        return cast(Physics2DBody*) bod;
    }

package:

    final void step(double dt)
    {
        cpSpaceStep(_space, dt);
    }
}
