# Qodot

Quake .map file support for Godot.

## Overview

Qodot extends the Godot editor to import Quake .map files, and provides an extensible framework for converting the entities and brushes contained therein into a scene-based node hierarchy with custom properties.

### Features

- Natively import .map files into Godot
- Supports
  - Brush geometry
  - Per-face textures and customized UVs
  - Precise trimesh collision
  - Entities with arbitrary collections of parameters
- Extensible tree population
  - Leverages the .map format's simple key/value property system
  - Spawn custom entities and brushes
- Supports the [TrenchBroom](https://kristianduske.com/trenchbroom/) editor
  - Simple, intuitive map editor with a strong feature set
  - Includes a simple Qodot game preset
  - Can be built upon with game-specific entities and brush properties

## Reasoning

Qodot was created to solve a long-standing problem with modern game engines: The lack of simple, accessible level editing functionality for users without 3D modeling expertise.

Unity, Unreal and Godot are all capable of CSG to some extent or other with varying degrees of usability, but lack fine-grained direct manipulation of geometry, as well as per-face texture and UV manipulation. It's positioned more as a prototyping tool to be used ahead of a proper art pass than a viable methodology.

Conversely, dedicated 3D modeling packages like Maya or Blender are very powerful and can iterate fast in experienced hands, but have an intimidating skill floor for users with a programming-focused background that just want to build levels for their game.

Enter the traditional level editor: Simple tools built for games like Doom, Quake and Duke Nukem 3D that operate in the design language of a video game and are created for use by designers, artists and programmers alike.

Thanks to years of community support, classic Quake is still alive, kicking, and producing high-quality content and mapping software alike. Due to its simplicity and continued popularity, the Quake .map format presents a novel solution.

## .map files

.map files are plaintext files which contain definitions of brushes and entities to be used by QBSP and it's related compiling tools to create a .bsp file used by Quake as levels.

The distinction is important to note: .bsp files are highly optimized, compiled versions of Quake maps designed to be plugged directly into its renderer. This imposes certain limitations and requirements, such as an offline light baking process and necessity for maps to form sealed volumes with the potential for frustrating leakage bugs.

.map files act more like a 3D interchange format; a way to store level data in simple, human-readable form for use by level editing software.

Since Godot isn't bound by the limitations of Quake's renderer, neither is Qodot. It reads map files directly, and converts them into level geometry using tool scripts. You don't have to worry about leaks, and combined with Godot's file-watching asset reimports it makes for a fast editor-to-editor interchange pipeline.

Currently the only supported format is the standard Quake 1 map file, but adding support for others (Quake 2, Quake 3, Hexen 2, etc.) should be relatively easy if a compelling use case presents itself.

.map files are structurured as a list of entities and brushes. Entities represent top-level game objects, and brushes represent convex hulls defined by the intersection of a set of planes.

Every .map file has a 'wordspawn' entity by default, which is used to store all of the level's static geometry brushes as well as various top-level data. Entities following the worldspawn may have an origin and rotation transform, as well as a set of attached brushes. These are used to implement various interactive elements in Quake, such as event triggers, buttons, elevators, doors, and teleport destinations.

[More information on the .map file spec can be found here.](http://www.gamers.org/dEngine/quake/QDP/qmapspec.html)

## Installation

To install Qodot, create res://addons/Qodot in your project folder and extract the contents of this repository into it.

## Usage

### In-Editor

Qodot's primary use case is as a bridge to an external map editor, allowing the user to iterate on a map file outside of Godot, then come back and see the changes immediately.

To bring a .map file into the editor, simply add it .map file to your Godot project and it will be imported automatically.

To add the contents of that map to a scene, simply add a QuakeMapNode (or derived class) to it and point it to your map file and texture directory.

Any Quake-compatible map editor can be used to generate .map files, but [TrenchBroom](https://kristianduske.com/trenchbroom/) is recommended and directly supported.

### Runtime

Qodot can also be used to generate maps at runtime, allowing an exported game to load levels prepared without need of the Godot editor.

To load a map at runtime, create an instance of the QuakeMapReader class from GDScript and call its read_map_file(file) method, which takes a File object pointing at the .map file you wish to load and returns a QuakeMap instance.

To convert the QuakeMap instance into usable level geometry, pass it into the set_map(map) method of a QuakeMapNode.

## Example Content

An example scene is available in Scenes/QodotExample.scene, and its source map file can be found in TrenchBroom/QodotExample.map

In order to open the example map in TrenchBroom, it will need access to the Qodot game configuration. See the TrenchBroom Integration section below for details.

## QuakeMapNode

QuakeMapNode is the main user-facing element of Qodot- it takes a QuakeMapFile object imported from a .map file and turns it into usable level geometry.

### Properties

#### Reload

Regenerates the map when clicked.

#### Mode

Decides how the .map file should be rendered.

- Plane Axes - Debug visualization of raw plane data
- Face Points - Debug visualization of intersecting plane vertices
- Brush Meshes - Full mesh representation with collision

#### Inverse Scale Factor

Used to convert from Quake units to arbitrary scene units; map coordinates are divided by this value during conversion into meshes.

The default of 16 is a best-effort mapping from Quake 3's '1 Unit = ~1 Inch' coordinates to Godot's preferred Metric measurement.

#### Autoload Map Path

The file path to your map.

ex. res://Maps/MyMap.map

#### Base Texture Path

The base search path for textures defined in the map file.

Quake maps use an extensionless '[package]/[texture]' format, so textures should be grouped into subdirectories.

ex. res://Textures/base/my-texture.png

#### Texture Extension

The file extension appended to quake-format texture names. Plain image formats are recommended for easy interoperation with map editors.

ex: .png, .jpg or .tres

## Extending Qodot

By default, Qodot provides basic conversion of brushes into StaticBody and Area nodes based on the presence of 'trigger' in their .map classname.

All entities outside of triggers and the default 'worldspawn' node used to hold static geometry will be spawned as simple Position3D placholders.

Lights are unsupported out of the box, and lighting levels using the Godot editor is recommended due to the disparity between its rendering model and that of a Quake level editor.

In order to extend Qodot with game-specific entities, you can extend the QuakeMapNode class and override the following methods:

### spawn_entity_node(classname: String) -> Node

Controls the spawning of entity nodes based on their classname. A typical implementation would be a match statement that enumerates the various game-specific classnames, then instantiates one as appropriate and returns it.

### should_spawn_brush_mesh(classname: String) -> bool

Controls the spawning of a MeshInstance for brushes with the given classname. Typically used to differentiate between geometry brushes, triggers and 'point entities' (a.k.a. entities with a position but no brush)

### should_spawn_brush_collision(classname: String) -> bool

Controls the spawning of a CollisionObject for brushes with the given classname. Defaults to true, but can be overridden to implement visual brushes that can be clipped through by the player.

### spawn_brush_collision_object(classname: String) -> CollisionObject

Controls the spawning of collision objects for brushes with the given classname. Typically used to differentiate between solid geometry and triggers.

## TrenchBroom Integration

To integrate Qodot with Trenchbroom, copy the contents of the TrenchBroom/Qodot folder (minus the .gdignore) into [your TrenchBroom install]/games/Qodot

Then, either open a Qodot-compatible map in TrenchBroom or create a new map from the user interface and select the Qodot profile. You will need to set the game directory to the parent directory of your textures folder in order for TrenchBroom to detect them.

The Qodot profile can be copied for use as the basis of a game-specific profile, but any maps created prior will need to be manually updated using a text editor to point at the new game name and .fgd file.

### Note

TrenchBroom will create an 'autosaves' folder containing map backups alongside any maps you edit with it, so make sure to create a .gdignore file within to prevent Godot from repeatedly importing several versions of the same map.
