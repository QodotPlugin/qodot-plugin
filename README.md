![](https://raw.githubusercontent.com/Shfty/qodot-extras/master/graphics/qodot_logo_small.png)

Quake *.map* file support for Godot.

![](https://raw.githubusercontent.com/Shfty/qodot-extras/master/screenshots/heading.png)

## Overview

Qodot extends the Godot editor to import Quake *.map* files, and provides an extensible framework for converting the entities and brushes contained therein into a scene-based node hierarchy with custom properties.

## Features

- Natively import *.map* files into Godot
- Supports
  - Brush geometry
  - Per-face textures and customized UVs
  - Precise trimesh collision
  - Entities with arbitrary collections of parameters
- Extensible tree population
  - Leverages the *.map* format's simple key/value property system
  - Spawn custom entities and brushes
- Supports the [TrenchBroom](#trenchbroom) editor
  - Simple, intuitive map editor with a strong feature set
  - Includes a simple Qodot game preset
  - Can be built upon with game-specific entities and brush properties

## Showcase

[![](https://raw.githubusercontent.com/Shfty/qodot-extras/master/showcase/sunkper-props-thumbnail.jpg)](https://raw.githubusercontent.com/Shfty/qodot-extras/master/showcase/sunkper-props.jpg)

Assorted props by [@SunkPer](https://twitter.com/SunkPer)

[![](https://raw.githubusercontent.com/Shfty/qodot-extras/master/showcase/sunkper-summer-island.gif)](https://cdn.discordapp.com/attachments/651209074930876416/659427504309796876/Project_Summer_Island_WIP_25.mp4)

Summer Island by [@SunkPer](https://twitter.com/SunkPer)

## Thesis

Qodot was created to solve a long-standing problem with modern game engines: The lack of simple, accessible level editing functionality for users without 3D modeling expertise.

Unity, Unreal and Godot are all capable of CSG to some extent or other with varying degrees of usability, but lack fine-grained direct manipulation of geometry, as well as per-face texture and UV manipulation. It's positioned more as a prototyping tool to be used ahead of a proper art pass than a viable methodology.

Conversely, dedicated 3D modeling packages like Maya or Blender are very powerful and can iterate fast in experienced hands, but have an intimidating skill floor for users with a programming-focused background that just want to build levels for their game.

Enter the traditional level editor: Simple tools built for games like Doom, Quake and Duke Nukem 3D that operate in the design language of a video game and are created for use by designers, artists and programmers alike. Thanks to years of community support, classic Quake is still alive, kicking, and producing high-quality content and mapping software alike. This continued popularity combined with its simplicity means the Quake *.map* format presents a novel solution.

## Documentation

Documentation is available on the [Qodot Wiki](https://github.com/ShiftyAxel/Qodot/wiki)

## Example Content

The repo contains an example project with a simple *.map* scene imported to a *.tscn*.

In order to open the example map in TrenchBroom, it will need access to the Qodot game configuration as specified in the [TrenchBroom](https://github.com/ShiftyAxel/Qodot/wiki/TrenchBroom#qodot-integration) wiki page.

## Qodot Elsewhere

[Discord - Qodot](https://discord.gg/c72WBuG)

[Reddit - Qodot](https://www.reddit.com/r/godot/comments/e41ldk/qodot_quake_map_file_support_for_godot/)

[Godot Forums - Qodot](https://godotforums.org/discussion/comment/30450#Comment_30450)

[Godot Asset Library - Qodot](https://godotengine.org/asset-library/asset/446)

[Shifty's Twitter](https://twitter.com/ShiftyAxel)

## Credits

[Kristian Duske](https://twitter.com/kristianduske) - For creating TrenchBroom and inspiring the creation of Qodot

[Arkii](https://github.com/GoomiChan) - For example code and handy documentation of the Valve 220 format

[TheRektafire](https://github.com/TheRektafire) - For a variety of useful tidbits on the .map format

[Calinou](https://github.com/Calinou) - For making Qodot work on case-sensitive systems

[Redhacker2](https://github.com/donovan1212) - For stress-testing Qodot to within an inch of its life and motivating me to improve it

[FreePBR.com](https://freepbr.com) - For royalty-free PBR example textures

[SunkPer](https://twitter.com/SunkPer) - For showcase screenshots
