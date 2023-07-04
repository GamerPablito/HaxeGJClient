# Haxe GameJolt Client

Heya there! GamerPablito here!

Thanks for use this custom client for GameJolt for Haxe, this has very useful functions for different purposes with a little better performance than the default libraries (such as the flixel file ~~"FlxGameJolt"~~ or the original ~~"gamejoltAPI"~~ library stuff).

This was originally made for some Friday Night Funkin' mods, but it can be used for any game made with Haxeflixel as well.

The purpose of this project is to make everything the best way possible, using less space and complexity for a better performance (and by that I mean it can be useful for computers with a very slow processing speed).

Hope this custom tool would come in handy to you :)

NOTE: Don't get confused with the GJ Integration made by [TentaRJ](https://github.com/TentaRJ/GameJolt-FNF-Integration)

## Special Features
- Includes haxe libraries like:
  - `Json` (used to cast specific information formats from the fetched data)
  - `Md5` (used to encript a special signature to access the API in a safe way)
  - `Sha1` (used as alternative for `Md5`, works the same)
  - `Bytes` (used to load information from web without lag)
  - `Events` (used to trigger actions with less effort)

- This client is totally independient, it doesn't requires any extra GameJolt libraries to work, cuz everything is written and composed here
- This also contains some files with info formats about how some data has to be received like, this in order to let the user know how to use the data in their game
- Has many extra features that can be fetched instantly without you have to code a lot for them
- Every file is full of instructions for each command, in order to do the things right if you don't know so much about it

## How to Use
1. Open the command prompt or Powershell and run: `haxelib install HaxeGJClient`
2. Open the `project.xml` file and write at the bottom of the libraries section.
 ```xml
 <haxelib name="HaxeGJClient">
 ```

## Still have doubts about its use?
If you're still have questions about how to use this client correctly, or if you want some menu templates to begin with for your game (FNF mods or anything else), you're free to talk to me by [Twitter](https://twitter.com/GamerPablito1) or Discord (GamerPablito#3132). I have no kind of special access you need to do this at all!
You can also check my [Youtube Channel](https://www.youtube.com/channel/UCpavbRRdISmsF_fpiAuVafg), where you can find a tutorial about its use.

## Special Thanks
- [EyeDaleHim](https://github.com/EyeDaleHim) : For suggest me about a better command for printing responses
- [MemeHoovy](https://github.com/MemeHovy) : For giving me a hand explaining differences between this integration and TentaRJ's one
- [TentaRJ](https://github.com/TentaRJ) : For being a huge inspiration for me to create this
- [bimagamongMOP](https://bimagamongmopmain.carrd.co/) : For making me realize a gramatical error in the code ("Trophie" to "Trophy")
- [xMediKat](https://www.xmedikat.live) : For suggest me ideas to get rid of lagspikes
