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
import serpent;

/**
 * The World class is reponsible for the integration of physics into the
 * game world. As such, physics data must be created *through* the World
 * to ensure it is correctly tracked.
 */
final class World2D
{

private:

    __gshared cpSpace* _space = null;

public:

    /**
     * Construct a new World2D instance.
     */
    this()
    {
        _space = cpSpaceNew();
        _space.gravity = cpVect(0, 0);
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
    Physics2DBody* createDynamicBody(EntityID id, double mass, double moment)
    {
        cpBody* bod = cpBodyNew(mass, moment);

        cpSpaceAddBody(_space, bod);
        bod.userData = cast(void*) id;

        return cast(Physics2DBody*) bod;
    }

    final @property void gravity(vec2f gravity) @trusted @nogc nothrow
    {
        _space.gravity = cpVect(cast(double) gravity.x, cast(double) gravity.y);
    }

package:

    extern (C) static final void updateBody(cpBody* _body, void* userdata)
    {
        auto view = cast(View!ReadWrite*) userdata;
        auto entity = cast(EntityID) _body.userData;
        auto transform = view.data!TransformComponent(entity);

        import std.stdio;

        writefln("Moving entity %d to %d %d", entity, cast(int) _body.p.x, cast(int) _body.p.y);
        transform.position.x = cast(float) _body.p.x;
        transform.position.y = cast(float) _body.p.y;
    }

    final void step(View!ReadWrite view, double dt)
    {
        cpSpaceStep(_space, dt);
        cpSpaceEachBody(_space, &updateBody, cast(void*)&view);
    }
}
