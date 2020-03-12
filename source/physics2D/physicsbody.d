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

module physics2D.physicsbody;

import chipmunk;
import serpent;

/**
 * Ensrre that a cpBody is correctly removed from the space and that
 * resources are returned to the OS
 */
final static void freeComponent(void* v)
{
    Physics2DBodyComponent* comp = cast(Physics2DBodyComponent*) v;
    if (comp.body is null)
    {
        return;
    }

    auto chipBody = cast(cpBody*) comp.body;

    /* Remove from parent space */
    if (chipBody.space !is null)
    {
        cpSpaceRemoveBody(chipBody.space, chipBody);
    }
    cpBodyFree(chipBody);

    comp.body = null;
}

/**
 * Encapsulates a Chipmunk2D cpBody
 */
final @serpentComponent(&freeComponent) struct Physics2DBodyComponent
{
    Physics2DBody* body;
}

/**
 * Physics2DBody is a lightweight wrapper around cpBody which provides
 * simpler management APIs.
 */
extern (C) final struct Physics2DBody
{

private:
    cpBody pt;
    alias pt this;

public:

    /**
     * Update position from a vec3f
     */
    final @property void position(vec3f position)
    {
        pt.p.x = cast(double) position.x;
        pt.p.y = cast(double) position.y;
    }
}
