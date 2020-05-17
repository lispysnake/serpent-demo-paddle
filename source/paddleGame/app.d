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

module paddleGame.app;

import serpent;

import serpent.audio;
import serpent.physics2d;

import bindbc.sdl;
import std.stdio;

import std.path : buildPath;
import std.format;
import std.datetime;

import paddleGame.stage;
import paddleGame.ai;
import paddleGame.idle;
import paddleGame.ball : BallComponent;

/**
 * Allow tracking our basic game status
 */
final enum GameStatus
{
    Stopped = 0,
    FadeToPlay,
    FadeToSplash,
    AwaitingServe,
    Served,
}

/* Simple no-op app */
final class PaddleGame : serpent.App
{

private:
    AudioManager audioManager;
    IdleProcessor idleProc;
    Track mainTrack;
    Track introTrack;
    Clip[5] impactClips;

    Clip winClip;
    Clip loseClip;
    Clip humanScoreClip;
    Clip enemyScoreClip;

    /**
     * Allow us to trivially track transitions
     */
    GameStatus status = GameStatus.FadeToSplash;

    Scene scene;
    Stage arena;
    AbstractWorld world;
    EntityID player;
    EntityID splash;
    EntityID enemyPaddle;
    EntityID obstacle1;
    EntityID obstacle2;
    bool keyUp = false;
    bool keyDown = false;
    bool gravity = false;
    bool demoMode = true;
    bool endDemoMode = false;
    bool levelSpawn = false;

    EntityID scoreHuman;
    int scoreHumanNumeric = 0;
    EntityID scoreEnemy;
    int scoreEnemyNumeric = 0;

    EntityID[] walls;

    Duration tweenSplash;
    Duration tweenSplashLength = dur!"msecs"(500);

    string assetBasePath = "";

    /**
     * Handle key release events
     */
    final void keyPressed(KeyboardEvent e)
    {
        endDemoMode = true;

        switch (e.scancode())
        {
        case SDL_SCANCODE_UP:
            keyUp = true;
            break;
        case SDL_SCANCODE_DOWN:
            keyDown = true;
            break;
        case SDL_SCANCODE_SPACE:
            if (!demoMode)
            {
                idleProc.schedule((view) => arena.spawnBall(view));
            }
            break;
        default:
            break;
        }
    }

    /**
     * Handle key release events
     */
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
     * Spawn the initial play area boundaries
     * All spawned elements are permanently part of the game
     * whether or not they're visible
     */
    final void spawnPlayArea(View!ReadWrite view)
    {
        walls = arena.spawnWalls(view);
        arena.spawnBorder(view);
        scoreHuman = arena.spawnScore(view, PaddleOwner.PlayerOne);
        scoreEnemy = arena.spawnScore(view, PaddleOwner.PlayerTwo);
    }

    /**
     * Reset the current play area (prior to demo or playable)
     */
    final void resetPlayArea(View!ReadWrite view)
    {
        /*
         * Lill all balls.
         */
        foreach (entityID, ballComp; view.withComponents!BallComponent)
        {
            view.killEntity(entityID.id);
        }

        /*
         * Kill all CPU players
         */
        foreach (entityID, cpu; view.withComponents!AIComponent)
        {
            if (cpu.edge != AIEdge.None)
            {
                view.killEntity(entityID.id);
            }
        }

        /* Reset scores now */
        scoreEnemyNumeric = 0;
        scoreHumanNumeric = 0;
        arena.setScore(view, scoreHuman, 0);
        arena.setScore(view, scoreEnemy, 0);

        if (player != 0)
        {
            view.killEntity(player);
        }
    }

    /**
     * Spawn world in demo configuration
     */
    final void spawnDemo(View!ReadWrite view)
    {
        resetPlayArea(view);

        arena.spawnBall(view);
        splash = arena.spawnSplash(view);
        player = arena.spawnPaddle(view, PaddleOwner.PlayerOne, PaddleType.Computer);
        enemyPaddle = arena.spawnPaddle(view, PaddleOwner.PlayerTwo, PaddleType.Computer);
        obstacle1 = arena.spawnPaddle(view, PaddleOwner.ObstacleOne, PaddleType.Computer);
        obstacle2 = arena.spawnPaddle(view, PaddleOwner.ObstacleTwo, PaddleType.Computer);
    }

    /**
     * Spawn world in the level configuration
     */
    final void spawnLevel(View!ReadWrite view)
    {
        resetPlayArea(view);

        player = arena.spawnPaddle(view, PaddleOwner.PlayerOne, PaddleType.Human);
        enemyPaddle = arena.spawnPaddle(view, PaddleOwner.PlayerTwo, PaddleType.Computer);
        audioManager.play(mainTrack);
        arena.spawnBall(view);
    }

    /**
     * Handle gameplay transitions
     */
    final void handleGameState(View!ReadWrite view)
    {
    }

public:

    this(AbstractWorld world, IdleProcessor idleProc)
    {
        this.world = world;
        this.idleProc = idleProc;

        import std.file : thisExePath, exists;
        import std.path : dirName;

        auto us = thisExePath();
        auto dirp = dirName(us);

        string[] assetPaths = [buildPath("assets"), buildPath("..", "assets")];

        foreach (p; assetPaths)
        {
            auto jr = buildPath(dirp, p);
            if (!exists(jr))
            {
                continue;
            }
            assetBasePath = jr;
        }
        if (assetBasePath == "")
        {
            writeln("CANNOT FIND ASSETS");
            import core.stdc.stdlib;

            exit(0);
        }
    }

    /**
     * Apply physics to player
     */
    final override void update(View!ReadWrite view)
    {
        audioManager.update();

        handleGameState(view);

        if (endDemoMode && demoMode)
        {
            tweenSplash += context.deltaTime();

            long timeNS;
            tweenSplash.split!("nsecs")(timeNS);
            auto tweenSplashMS = timeNS / 1_000_000.0f;
            tweenSplashLength.split!("nsecs")(timeNS);
            auto tweenSplashLengthMS = timeNS / 1_000_000.0f;

            auto factor = (cast(float) tweenSplashMS / cast(float) tweenSplashLengthMS).clamp(0.0f,
                    1.0f);
            if (tweenSplashLengthMS < tweenSplashMS)
            {
                factor = 1.0f;
            }

            /**
             * Simple helper to tween the value (linear)
             */
            void tweenValue(EntityID id, float oldValue, float newValue)
            {
                auto delta = (newValue - oldValue) * factor;
                auto color = view.data!ColorComponent(id);
                color.rgba.a = oldValue + delta;
            }

            tweenValue(splash, 1.0f, 0.0f);
            tweenValue(scoreEnemy, 0.0f, 1.0f);
            tweenValue(scoreHuman, 0.0f, 1.0f);

            if (tweenSplash >= tweenSplashLength)
            {
                endDemoMode = false;
                demoMode = false;
                view.killEntity(splash);
            }
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
        audioManager.crossFadeTime = 1000;
        audioManager.trackVolume = 0.25f;
        audioManager.effectVolume = 0.1f;
        mainTrack = new Track(buildPath(assetBasePath, "audio", "MainLoop.ogg"));
        introTrack = new Track(buildPath(assetBasePath, "audio", "Intro.ogg"));

        winClip = new Clip(buildPath(assetBasePath, "audio", "you_win.ogg"));
        loseClip = new Clip(buildPath(assetBasePath, "audio", "you_lose.ogg"));

        humanScoreClip = new Clip(buildPath(assetBasePath, "audio", "PlayerScored.ogg"));
        enemyScoreClip = new Clip(buildPath(assetBasePath, "audio", "EnemyScored.ogg"));

        foreach (i; 0 .. 5)
        {
            impactClips[i] = new Clip(buildPath(assetBasePath, "audio",
                    "impactGeneric_light_00%d.ogg".format(i)));
        }

        audioManager.play(introTrack);

        /* Construct the play arena */
        arena = new Stage(this.world, this.assetBasePath,
                context.display.logicalWidth(), context.display.logicalHeight());

        arena.scoreEvent.connect(&onScored);
        arena.impactEvent.connect(&onImpact);
        arena.invertObstacleEvent.connect(&onInversion);

        scene = new Scene("default");
        context.display.addScene(scene);
        scene.addCamera(new OrthographicCamera());

        context.input.keyPressed.connect(&keyPressed);
        context.input.keyReleased.connect(&keyReleased);

        spawnPlayArea(view);
        spawnDemo(view);

        return true;
    }

    final void onScored(EntityID wallID, EntityID ballID)
    {
        import paddleGame : MaximumScore;

        if (wallID == walls[2])
        {
            ++scoreHumanNumeric;
            idleProc.schedule((view) => arena.setScore(view, scoreHuman, scoreHumanNumeric));
            if (!demoMode)
            {
                if (scoreHumanNumeric == MaximumScore)
                {
                    audioManager.play(winClip);
                }
                else
                {
                    audioManager.play(humanScoreClip);
                }
            }
        }
        else if (wallID == walls[3])
        {
            ++scoreEnemyNumeric;
            idleProc.schedule((view) => arena.setScore(view, scoreEnemy, scoreEnemyNumeric));
            if (!demoMode)
            {
                if (scoreEnemyNumeric == MaximumScore)
                {
                    audioManager.play(loseClip);
                }
                else
                {
                    audioManager.play(enemyScoreClip);
                }
            }
        }

        idleProc.schedule((view) => view.killEntity(ballID));

        /* Auto spawn new ball for demo mode */
        if (demoMode)
        {
            idleProc.schedule((view) => arena.spawnBall(view));
        }
    }

    /**
     * For any given impact, play a sound when not in demo
     * mode
     */
    final void onImpact(EntityID oneID, EntityID twoID)
    {
        if (demoMode)
        {
            return;
        }
        import std.random : uniform;

        auto idx = uniform(0, impactClips.length);
        audioManager.play(impactClips[idx]);
    }

    /**
     * Invert direction of paddle
     */
    final void onInversion(EntityID id)
    {
        idleProc.schedule((view) {
            auto physics = view.data!PhysicsComponent(id);
            auto vel = physics.body.velocity;
            physics.body.velocity = vec2f(0.0f, -vel.y);
        });
    }
}
