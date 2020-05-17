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

module paddleGame.fadeManager;

import serpent;
import std.datetime;

/**
 * Wrapper to help us track whether we fade-in or fade-out a thing.
 */
final struct FadeOp
{
    EntityID id;
    bool fadeIn;

    this(EntityID id, bool fadeIn)
    {
        this.id = id;
        this.fadeIn = fadeIn;
    }
}

/**
 * The FadeManager is super derpy and simple and lets us fade-in/fade-out
 * things with a fixed transition.
 */
final class FadeManager
{

private:

    Duration _fadeLength = dur!"msecs"(1000);
    Duration _timePassed;
    Context context;

    __gshared GreedyArray!FadeOp fadeSet;

public:

    this(Context context)
    {
        this.context = context;
        fadeSet = GreedyArray!FadeOp(3, 0);
    }

    /**
     * Return the animation length
     */
    pure final @property Duration length() @safe @nogc nothrow
    {
        return _fadeLength;
    }

    /**
     * Set the animation length
     */
    pure final @property void length(Duration d) @safe @nogc nothrow
    {
        _fadeLength = d;
    }

    final void add(EntityID id, bool fadeIn = true)
    {
        fadeSet[fadeSet.count] = FadeOp(id, fadeIn);
    }

    final void update()
    {
        _timePassed += context.deltaTime();

        long timeNS;
        _timePassed.split!("nsecs")(timeNS);
        auto tweenMS = timeNS / 1_000_000.0f;
        _fadeLength.split!("nsecs")(timeNS);
        auto tweenLengthMS = timeNS / 1_000_000.0f;

        auto factor = (cast(float) tweenMS / cast(float) tweenLengthMS).clamp(0.0f, 1.0f);
        if (tweenLengthMS < tweenMS)
        {
            factor = 1.0f;
        }
    }
}
