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

import serpent.audio;
import serpent.physics2d;

import bindbc.sdl;
import std.getopt;
import std.stdio;

import std.path : buildPath;
import std.format;

import stage;

import ai;

/* Simple no-op app */
class MyApp : serpent.App
{

private:
    AudioManager audioManager;
    Track mainTrack;
    Clip[5] impactClips;

    Scene scene;
    Stage arena;
    AbstractWorld world;
    EntityID player;
    EntityID splash;
    EntityID ballID;
    EntityID enemyPaddle;
    EntityID obstacle1;
    EntityID obstacle2;
    bool keyUp = false;
    bool keyDown = false;
    bool gravity = false;
    bool demoMode = true;
    bool levelSpawn = false;
    bool moarBalls = false;

    EntityID scoreHuman;
    int scoreHumanNumeric = 0;
    EntityID scoreEnemy;
    int scoreEnemyNumeric = 0;

    EntityID ballKill = 0;

    EntityID[] walls;

    final void keyPressed(KeyboardEvent e)
    {
        demoMode = false;

        switch (e.scancode())
        {
        case SDL_SCANCODE_UP:
            keyUp = true;
            break;
        case SDL_SCANCODE_DOWN:
            keyDown = true;
            break;
        case SDL_SCANCODE_SPACE:
            moarBalls = true;
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
        case SDL_SCANCODE_G:
            gravity = !gravity;
            if (gravity)
            {
                world.gravity = vec2f(0.0f, 0.003f);
            }
            else
            {
                world.gravity = vec2f(0.0f, 0.0f);
            }
            break;
        default:
            break;
        }
    }

    /**
     * Spawn world in demo configuration
     */
    final void spawnDemo(View!ReadWrite view)
    {
        splash = arena.spawnSplash(view);
        player = arena.spawnPaddle(view, PaddleOwner.PlayerOne, PaddleType.Computer);
        enemyPaddle = arena.spawnPaddle(view, PaddleOwner.PlayerTwo, PaddleType.Computer);
        obstacle1 = arena.spawnPaddle(view, PaddleOwner.ObstacleOne, PaddleType.Computer);
        obstacle2 = arena.spawnPaddle(view, PaddleOwner.ObstacleTwo, PaddleType.Computer);
        ballID = arena.spawnBall(view);
        walls = arena.spawnWalls(view);
    }

    /**
     * Spawn world in the level configuration
     */
    final void spawnLevel(View!ReadWrite view)
    {
        view.killEntity(player);
        view.killEntity(splash);
        view.killEntity(ballID);
        view.killEntity(enemyPaddle);
        view.killEntity(obstacle1);
        view.killEntity(obstacle2);

        player = arena.spawnPaddle(view, PaddleOwner.PlayerOne, PaddleType.Human);
        enemyPaddle = arena.spawnPaddle(view, PaddleOwner.PlayerTwo, PaddleType.Computer);
        obstacle1 = arena.spawnPaddle(view, PaddleOwner.ObstacleOne, PaddleType.Computer);
        obstacle2 = arena.spawnPaddle(view, PaddleOwner.ObstacleTwo, PaddleType.Computer);
        ballID = arena.spawnBall(view);

        scoreHuman = arena.spawnScore(view, PaddleOwner.PlayerOne);
        scoreEnemy = arena.spawnScore(view, PaddleOwner.PlayerTwo);

        arena.spawnBorder(view);
    }

public:

    this(AbstractWorld world)
    {
        this.world = world;
    }

    /**
     * Apply physics to player
     */
    final override void update(View!ReadWrite view)
    {
        if (ballKill != 0)
        {
            view.killEntity(ballKill);
            import std.stdio;

            writefln("Killed ball %d", ballKill);
            ballKill = 0;
        }

        if (demoMode)
        {
            return;
        }
        if (!levelSpawn)
        {
            spawnLevel(view);
            levelSpawn = true;
            return;
        }

        arena.setScore(view, scoreEnemy, scoreEnemyNumeric);
        arena.setScore(view, scoreHuman, scoreHumanNumeric);

        if (moarBalls)
        {
            arena.spawnBall(view);
            moarBalls = false;
        }

        auto phys = view.data!PhysicsComponent(player);
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
        audioManager = new AudioManager();
        audioManager.trackVolume = 0.1f;
        mainTrack = new Track(buildPath("assets", "audio", "MainLoop.ogg"));

        foreach (i; 0 .. 5)
        {
            impactClips[i] = new Clip(buildPath("assets", "audio",
                    "impactGeneric_light_00%d.ogg".format(i)));
        }

        audioManager.play(mainTrack);

        /* Construct the play arena */
        arena = new Stage(this.world, context.display.logicalWidth(),
                context.display.logicalHeight());

        arena.scoreEvent.connect(&onScored);

        scene = new Scene("default");
        context.display.addScene(scene);
        scene.addCamera(new OrthographicCamera());

        context.input.keyPressed.connect(&keyPressed);
        context.input.keyReleased.connect(&keyReleased);

        spawnDemo(view);

        return true;
    }

    final void onScored(EntityID wallID, EntityID ballID)
    {
        import std.stdio;

        if (wallID == walls[2])
        {
            ++scoreHumanNumeric;
            writeln("Player One Scored");
        }
        else if (wallID == walls[3])
        {
            writeln("Player Two Scored");
            ++scoreEnemyNumeric;
        }
        else
        {
            writeln("Wtf.");
        }

        writefln("Wall %d hit by ball %d", wallID, ballID);
        ballKill = ballID;
    }
}

/* Main entry */
int main(string[] args)
{
    bool vulkan = false;
    bool fullscreen = false;
    bool debugMode = false;
    bool disableVsync = false;
    auto argp = getopt(args, std.getopt.config.bundling, "v|vulkan",
            "Use Vulkan instead of OpenGL", &vulkan, "f|fullscreen",
            "Start in fullscreen mode", &fullscreen, "d|debug", "Enable debug mode",
            &debugMode, "n|no-vsync", "Disable VSync", &disableVsync);

    if (argp.helpWanted)
    {
        defaultGetoptPrinter("serpent demonstration\n", argp.options);
        return 0;
    }

    /* Context is essential to *all* Serpent usage. */
    auto context = new Context();
    context.display.title("#serpent Paddle Demo").size(1366, 768);
    context.display.logicalSize(1366, 768);
    context.display.backgroundColor = 0x2d3436ff;

    if (vulkan)
    {
        context.display.title = context.display.title ~ " [Vulkan]";
    }
    else
    {
        context.display.title = context.display.title ~ " [OpenGL]";
    }

    /* We want OpenGL or Vulkan? */
    if (vulkan)
    {
        writeln("Requesting Vulkan display mode");
        context.display.pipeline.driverType = DriverType.Vulkan;
    }
    else
    {
        writeln("Requesting OpenGL display mode");
        context.display.pipeline.driverType = DriverType.OpenGL;
    }

    if (fullscreen)
    {
        writeln("Starting in fullscreen mode");
        context.display.fullscreen = true;
    }

    if (debugMode)
    {
        writeln("Starting in debug mode");
        context.display.pipeline.debugMode = true;
    }

    if (disableVsync)
    {
        writeln("Disabling vsync");
        context.display.pipeline.verticalSync = false;
    }

    auto phys = new PhysicsProcessor();
    auto world = phys.world;
    world.iterations = 10;
    context.systemGroup.add(phys);
    context.systemGroup.add(new AIProcessor());

    /* TODO: Remove need for casts! */
    import serpent.graphics.pipeline.bgfx;

    auto pipe = cast(BgfxPipeline) context.display.pipeline;
    pipe.addRenderer(new SpriteRenderer());

    return context.run(new MyApp(world));
}
