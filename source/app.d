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

import serpent;
import serpent.graphics.sprite;

import bindbc.sdl;

import stage;
import physics2D;

/* Simple no-op app */
class MyApp : serpent.App
{

private:
    Scene scene;
    Stage arena;

    final void keyPressed(KeyboardEvent e)
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_UP:
            break;
        case SDL_SCANCODE_DOWN:
            break;
        case SDL_SCANCODE_SPACE:
            break;
        default:
            break;
        }
    }

    final void keyReleased(KeyboardEvent e)
    {
        switch (e.scancode)
        {
        case SDL_SCANCODE_F:
            context.display.fullscreen = !context.display.fullscreen;
            break;
        case SDL_SCANCODE_Q:
            context.quit();
            break;
        default:
            break;
        }
    }

public:

    final override bool bootstrap(View!ReadWrite view)
    {
        /* Construct the play arena */
        arena = new Stage(context.display.logicalWidth(), context.display.logicalHeight());

        scene = new Scene("default");
        context.display.addScene(scene);
        scene.addCamera(new OrthographicCamera());

        context.input.keyPressed.connect(&keyPressed);
        context.input.keyReleased.connect(&keyReleased);

        /* Spawn the paddles */
        arena.spawnPaddle(view, true);
        arena.spawnPaddle(view, false);

        /* Spawn first play ball */
        arena.spawnBall(view);

        return true;
    }
}

/* Main entry */
void main()
{
    auto context = new serpent.Context();
    context.display.pipeline.driverType = DriverType.Vulkan;
    context.display.size(1366, 768);
    context.display.logicalSize(1366, 768);
    context.display.title = "#serpent Paddle Demo";

    /* Handle all physics through chipmunk */
    context.systemGroup.add(new Physics2DProcessor());

    /* TODO: Remove need for casts! */
    import serpent.graphics.pipeline.bgfx;

    auto pipe = cast(BgfxPipeline) context.display.pipeline;
    pipe.addRenderer(new SpriteRenderer());

    context.run(new MyApp);
}
