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
- Supports the [TrenchBroom](https://github.com/Shfty/qodot-plugin/wiki/TrenchBroom) editor
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

[The Qodot example content repository](https://github.com/Shfty/qodot-example) contains a Godot project showing off its functionality with a simple `.map` file imported into a `.tscn`. Installation and usage instructions can be found in its README.

## Extra Content

[The Qodot extra content repository](https://github.com/Shfty/qodot-extras) contains a set of additional resources, such as map editor plugins, logo graphics, showcase content and screenshots.

## Qodot Elsewhere

[Discord - Qodot](https://discord.gg/c72WBuG)

[Reddit - Qodot](https://www.reddit.com/r/godot/comments/e41ldk/qodot_quake_map_file_support_for_godot/)

[Godot Forums - Qodot](https://godotforums.org/discussion/21573/qodot-quake-map-file-support-for-godot)

[Godot Asset Library - Qodot](https://godotengine.org/asset-library/asset/446)

[Shifty's Twitter](https://twitter.com/ShiftyAxel)

## Support

If you'd like to support the ongoing development of Qodot, donations are accepted via PayPal:

[![Donate with PayPal button](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=D8FJ3RX3WSQJS&source=url)

## Credits

[Kristian Duske](https://twitter.com/kristianduske) - For creating TrenchBroom and inspiring the creation of Qodot

[Arkii](https://github.com/GoomiChan) - For example code and handy documentation of the Valve 220 format

[TheRektafire](https://github.com/TheRektafire) - For a variety of useful tidbits on the .map format

[Calinou](https://github.com/Calinou) - For making Qodot work on case-sensitive systems

[SunkPer](https://twitter.com/SunkPer) - For showcase screenshots

[lordee](https://github.com/lordee), [DistractedMOSFET](https://github.com/distractedmosfet) and [winadam](https://github.com/winadam) - For laying the groundwork of the FGD export and entity scripting systems.

[fossegutten](https://github.com/fossegutten) - For a typed GDScript pass

[Corruptinator](https://github.com/Corruptinator) - For the idea of using TrenchBroom groups as a scene tree.

[FreePBR.com](https://freepbr.com) - For royalty-free PBR example textures
