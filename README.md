# Haxe GameJolt Client

Heya there! GamerPablito here!

Thanks for use this custom client for GameJolt for Haxe, this has very useful functions for different purposes with a little better performance than the default libraries (such as the flixel file ~~"FlxGameJolt"~~ or the original ~~"gamejoltAPI"~~ library stuff).

This was originally made for some Friday Night Funkin' mods, but it can be used for any game made with Haxeflixel as well.

The purpose of this project is to make everything the best way possible, using less space and complexity for a better performance (and by that I mean it can be useful for computers with a very slow processing speed).

Hope this custom tool would come in handy to you :)

NOTE: Don't get confused with the GJ Integration made by [TentaRJ](https://github.com/TentaRJ/GameJolt-FNF-Integration)

## Special Features
- Includes haxe libraries like:
  - `Http` (used to track info from the GameJolt API)
  - `Json` (used to cast specific information formats from the fetched data)
  - `Md5` (used to encript a special signature to access the API in a safe way)
  - `Sha1` (used as alternative for `Md5`, works the same)
- This client is totally independient, it doesn't requires any extra GameJolt libraries to work, cuz everything is written and composed here
- This also contains some files with info formats about how some data has to be received like, this in order to let the user know how to use the data in their game
- Has many extra features that can be fetched instantly without you have to code a lot for them
- Every file is full of instructions for each command, in order to do the things right if you don't know so much about it

## How to Use in Game
1. Download this repository
2. Copy the `gamejolt` folder into the `source` folder of your game
3. Using the `GJKeys.hx` file, put in there your game data from GameJolt.<br>WARNING: You must add the line `source/gamejolt/GJKeys.hx` into the `.gitignore` file of your game directory, this in order to avoid the upload the file of the private data to GitHub.

## How to Use in FNF
You must do the same steps from before, then go to the `project.xml` file and add the following line (this in order to make the GJ related stuff you make in the mod to be toggled):

```xml
<define name="GAMEJOLT_ALLOWED" if="desktop" unless="ACHIEVEMENTS_ALLOWED" />

<!-- Don't forget to comment the ACHIEVEMENTS_ALLOWED line ofc-->
<!-- define name="ACHIEVEMENTS_ALLOWED" /-->
```

With that on mind, every time you insert a command from this in some part of your game, make sure its limited by the .xml conditional: `#if GAMEJOLT_ALLOWED ... #end` (cuz this client is made for computers only, and without the `ACHIEVEMENTS_ALLOWED` stuff getting in its way).
Example:
```haxe
#if GAMEJOLT_ALLOWED
import gamejolt.GJClient;
#end
  
class Example extends FlxUIState
{
  override function create()
  {
    super.create();

    #if GAMEJOLT_ALLOWED
    GJClient.initialize();
    #end
  }
}
```

You can find some menu templates that uses this on [here](https://github.com/GamerPablito/FNF-GameJolt-Menus) if you prefer!

## Still have doubts about its use?
If you're still have questions about how to use this client correctly, or if you want some menu templates to begin with for your game (FNF mods or anything else), you're free to talk to me by [Twitter](https://twitter.com/GamerPablito1) or Discord (GamerPablito#3132). I have no kind of special access you need to do this at all!

## Special Thanks
- [EyeDaleHim](https://github.com/EyeDaleHim) : For suggest me about a better command for printing responses
- [MemeHoovy](https://github.com/MemeHovy) : For giving me a hand explaining differences between this integration and TentaRJ's one
- [TentaRJ](https://github.com/TentaRJ) : For being a huge inspiration for me to create this
- [bimagamongMOP](https://bimagamongmopmain.carrd.co/) : For making me realize a gramatical error in the code ("Trophie" to "Trophy")
