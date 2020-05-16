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

module idle;

import serpent;

alias void delegate(View!ReadWrite view) idleCallback;

final struct CallbackWrapper
{
    idleCallback cb;
}

/**
 * The IdleProcessor is currently very simple, but will eventually
 * be upstreamed into Serpent to have "do later" functionality.
 */
final class IdleProcessor : Processor!ReadWrite
{

private:

    __gshared GreedyArray!idleCallback _callbacks;

public:

    this()
    {
        _callbacks = GreedyArray!idleCallback(0, 0);
    }

    /**
     * Step through all idle callbacks and run them, removing them
     * from the stack
     */
    final override void run(View!ReadWrite view)
    {
        foreach (ref cb; _callbacks.data)
        {
            cb(view);
        }
        _callbacks.reset();
    }

    /**
     * Copy lambda/function to idle processor stack for later
     * execution
     */
    final void schedule(idleCallback cb)
    {
        _callbacks[_callbacks.count] = cb;
    }
}
