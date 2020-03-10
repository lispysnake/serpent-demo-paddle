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

module physics2D.processor;

import chipmunk;
import serpent;

/**
 * The Physics2DProcessor should be added to a serpent Context when support
 * for 2D physics is required.
 *
 * It is internally powered by the Chipmunk library.
 */
final class Physics2DProcessor : Processor!ReadWrite
{

private:

    /**
     * Underlying 2D space. We only permit one space globally.
     */
    cpSpace* _space = null;

public:

    /**
     * Initialise Chipmunk
     */
    final override void bootstrap(View!ReadWrite view)
    {
        _space = cpSpaceNew();
    }

    /**
     * Shutdown Chipmunk
     */
    final override void finish(View!ReadWrite view)
    {
        cpSpaceFree(_space);
    }

    /**
     * Update for the current frame step
     */
    final override void run(View!ReadWrite view)
    {
        auto deltaTime = context.frameTime();
        cpSpaceStep(_space, deltaTime);
    }

    /**
     * Return the underlying space
     */
    pure final const(cpSpace*) space() @safe @nogc nothrow
    {
        return _space;
    }
}
