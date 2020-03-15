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
    World2D world;
    EntityID player;
    bool keyUp = false;
    bool keyDown = false;

    final void keyPressed(KeyboardEvent e)
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_UP:
            keyUp = true;
            break;
        case SDL_SCANCODE_DOWN:
            keyDown = true;
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
        case SDL_SCANCODE_UP:
            keyUp = false;
            break;
        case SDL_SCANCODE_DOWN:
            keyDown = false;
            break;
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

    this(World2D world)
    {
        this.world = world;
    }

    /**
     * Apply physics to player
     */
    final override void update(View!ReadWrite view)
    {
        auto phys = view.data!Physics2DBodyComponent(player);
        if (keyUp)
        {
            phys.body.velocity = vec2f(0.0f, -0.3f);
        }
        else if (keyDown)
        {
            phys.body.velocity = vec2f(0.0f, 0.3f);
        }
        else
        {
            phys.body.velocity = vec2f(0.0f, 0.0f);
        }
    }

    final override bool bootstrap(View!ReadWrite view)
    {
        /* Construct the play arena */
        arena = new Stage(this.world, context.display.logicalWidth(),
                context.display.logicalHeight());

        scene = new Scene("default");
        context.display.addScene(scene);
        scene.addCamera(new OrthographicCamera());

        context.input.keyPressed.connect(&keyPressed);
        context.input.keyReleased.connect(&keyReleased);

        /* Spawn the paddles */
        player = arena.spawnPaddle(view, true);
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
    auto phys = new Physics2DProcessor();
    auto world = phys.world;
    context.systemGroup.add(new Physics2DProcessor());

    /* TODO: Remove need for casts! */
    import serpent.graphics.pipeline.bgfx;

    auto pipe = cast(BgfxPipeline) context.display.pipeline;
    pipe.addRenderer(new SpriteRenderer());

    context.run(new MyApp(world));
}
