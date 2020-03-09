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

/**
 * The Stage is basically our game layout. It is divided as such that
 * it has bounding boxes for collisions.
 */

final class Stage
{

private:

    box2f worldTop;
    box2f worldLeft;
    box2f worldRight;
    box2f worldBottom;
    int _width = 0;
    int _height = 0;

public:

    @disable this();

    /**
     * Construct a new Stage with the given width and height
     */
    this(int width, int height)
    {
        _width = width;
        _height = height;
    }

    /**
     * Return stage width
     */
    pure final const @property int width() @safe @nogc nothrow
    {
        return _width;
    }

    /**
     * Return stage height
     */
    pure final const @property int height() @safe @nogc nothrow
    {
        return _height;
    }
}
