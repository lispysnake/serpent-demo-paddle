Weekly TODO

### Blocking Demo Release

 - [x] Fix bottom wall to be within stage bounds
 - [x] Convert left/right walls into sensors
 - [x] Add callbacks to know who 'scored'
 - [x] Display scores on screen
 - [x] Make computer able to control both players for demo function
 - [x] Add start screen utilising demo
 - [x] Fix texture scaling as it is ugly in full screen
 - [x] Add some kind of world decoration to make less boring
 - [x] Add obstacles
 - [x] Add SegmentShape to physics2d
 - [x] Restore accumulator for now in physics2d
 - [x] Add background music (`serpent-audio`)
 - [x] Add impact SFX for walls and paddles (`serpent-audio`)
 - [x] Add intro music, crossfade to main loop on 'start'
 - [x] Fade out the splash (quickly) when starting
 - [ ] Fix collision shape on paddles (no slop overlap or offset)
 - [ ] Huge cleanup to make it feel more game-like
 - [ ] Fix/cleanup AI logic to stop Obstacle paddles going for lunch
       Easiest method is to stop AI Controller being responsible for
       Obstacles and add inversion (circle) sensors to obstacle paddles
       to hit static bodies.

### Could Be Nice

 - [ ] Potentially add powerups (multiple ball spawn)
 - [ ] Add sprite rotation so ball rotates with physics correctly
 - [ ] Add drawing code to chipmunk (primitives) so we can *visualise* the physics, man.

