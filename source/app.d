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

/* Simple no-op app */
class MyApp : serpent.App
{

    Scene scene;

    final override bool bootstrap(View!ReadWrite view)
    {
        scene = new Scene("default");
        context.display.addScene(scene);
        scene.addCamera(new OrthographicCamera());

        /* Player paddle */
        auto ent = view.createEntity();
        auto tex = new Texture("assets/paddle.png");
        auto sprite = SpriteComponent();
        auto trans = TransformComponent();
        trans.position.x = 5.0f;
        trans.position.y = 75.0f;
        sprite.texture = tex;
        view.addComponent(ent, sprite);
        view.addComponent(ent, trans);

        /* CPU paddle */
        auto entCPU = view.createEntity();
        view.addComponent(entCPU, sprite);
        auto trans2 = TransformComponent();
        trans2.position.x = context.display.logicalWidth - tex.width - 5.0f;
        trans2.position.y = 75.0f;
        view.addComponent(entCPU, trans2);
        return true;
    }
}

/* Main entry */
void main()
{
    auto context = new serpent.Context();
    context.display.pipeline.driverType = DriverType.Vulkan;
    context.display.size(1366, 768);
    context.display.logicalSize(480, 270);
    context.display.title = "#serpent Paddle Demo";
    context.display.backgroundColor = 0x0;

    /* TODO: Remove need for casts! */
    import serpent.graphics.pipeline.bgfx;

    auto pipe = cast(BgfxPipeline) context.display.pipeline;
    pipe.addRenderer(new SpriteRenderer());

    context.run(new MyApp);
}
