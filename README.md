SceneKRift
===========

[![](http://rototyping.com/AltroHello.png)](http://rototyping.com/AltroHello.png)

SceneKRift is a playground for experimenting with the Oculus Rift, Razer Hydra, and SceneKit. It currently has some procedural terrain, L-System trees and the ability to paint in the sky.

The sky-painting currently uses the [Point Cloud Library](http://pointclouds.org/), which means that some dependencies snuck in. You'll need to install PCL, Eigen and Boost to run the Altro target. This is temporary until I either rip out PCL or bundle the deps along with the project.

Plug your Rift in for VR play, or leave it unplugged to use your desk-mounted display.

You can also run the original OpenWorldTest, which has been mutated to use the world protocol I built, but I haven't rotated it into standard openGL coordinates yet so it's all sideways.

Probably next in the pipe are changing the sky painting to get rid of dependencies and increase performance, and fixing the hydra integration/adding a sane mouselook so you don't have to put a crick in your neck when you want to turn.

Pre-fork README follows...

OpenWorldTest
=============


[![](https://lh4.googleusercontent.com/-f62ZF5u1IIw/UPMZluT2lVI/AAAAAAAABAQ/dZnO8cYG_aI/s1409/Screen%2520Shot%25202013-01-12%2520at%252023.56.56.png)](https://lh4.googleusercontent.com/-f62ZF5u1IIw/UPMZluT2lVI/AAAAAAAABAQ/dZnO8cYG_aI/s1409/Screen%2520Shot%25202013-01-12%2520at%252023.56.56.png)


WHAT IS THIS?
=============

This is a SceneKit project that uses more advanced techniques like fullscreen shaders, procedural level generation, chunk loading/unloading, as well as mouse/joypad first-person controls.

There are quite a few performance techniques that took me some time to work out in this project, so I thought it would be best to open source it - needs of the many, etc.


THANKS
=============

Many thanks go to the following people, without whom I'd never have got this far with SceneKit:

Jeff LaMarche, Tom Irving, Wade Tregaskis, and Thomas Goossens
