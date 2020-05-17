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

module paddleGame.countdownManager;

import serpent;
import std.datetime;
import std.signals;

/**
 * The CountdownManager is responsible for managing the initial
 * 3, 2, 1 countdown. Nothing fancy.
 */
final class CountdownManager
{

private:

    Duration _timePassed;
    Context context;
    bool counting = false;
    int countDown = 3;

    final void emitCountdown()
    {
        if (countDown == 0)
        {
            counting = false;
        }
        stepped.emit(countDown);
    }

public:

    mixin Signal!(int) stepped;

    this(Context context)
    {
        this.context = context;
    }

    final void start()
    {
        _timePassed = dur!"msecs"(0);
        counting = true;
        countDown = 3;
    }

    final void update()
    {
        if (!counting)
        {
            return;
        }
        _timePassed += context.deltaTime();
        long ms;
        _timePassed.split!("msecs")(ms);
        if (ms >= 1000)
        {
            countDown--;
            emitCountdown();
            _timePassed = dur!"msecs"(0);
        }
    }
}
