# GameJolt Adaptation for FNF and Haxeflixel

Heya there! GamerPablito here!

Thanks for use this custom client for GameJolt, this has very useful functions
for different purposes with a little better performance than the default libraries
(such as the flixel file ~~"FlxGameJolt"~~ or the original ~~"gamejoltAPI"~~ library stuff).

This was originally made for some FNF mods, but it can be used for any game made with Haxeflixel as well.

The purpose of this project is to make everything the best way possible,
using less space and complexity for a better performance (and by that I mean
it can be useful for computers with a very slow processing speed)
Hope this custom tool would come in handy to you :)

## Special Features
- Includes `haxe` libraries like:
  - `Http` (used to track info from the GameJolt API)
  - `Json` (used to cast specific information formats from the fetched data)
  - `Md5` (used to encript a special signature to access the API in a safe way)
  - `Sha1` (it's an alternative for `crypto.Md5`, works the same)
- This client is totally independient, it doesn't requires any extra GameJolt libraries to work, cuz everything is written and composed here
- This also contains some files with info formats about how some data has to be received like, this in order to let the user know how to use the data in their game
- Has many extra features that can be fetched instantly without you have to code a lot for them
- Every file is full of instructions for each command, in order to do the things right if you don't know so much about it

## How to Use in Game
1. Download this repository
2. Copy the `gamejolt` folder into the `source` folder of your game
3. Once copied, you must create a `GJKeys.hx` file into the `gamejolt` folder, where you'll put the Game GJ Data for the client, this will remain with yourself in order to avoid hackers.
Here's a template:
```
package gamejolt;

class GJKeys
{
  public static var id:Int = 0; // Your Game ID
  public static var key:String = ''; // Your Game Private Key
}
```
4. When you're about to upload the source code to GitHub, you must go first to the `.gitignore` file, this is where the ignored files are specified to GitHub for don't include them in commits, if you don't have one so create one, then add the directory of the `GJKeys.hx` file to it (this to make GitHub to don't upload that file).
Example:
```
export/
.vscode/
APIStuff.hx
art/build_x32-officialrelease.bat
art/build_x64-officialrelease.bat
art/test_x64-debug-officialrelease.bat

source/gamejolt/GJKeys.hx
```

Note: Every time you insert a command from this in some part of your game, make sure its limited by the .xml conditional: "if desktop", cuz this client is made for computers only. Example:
  ```
  #if desktop
  import gamejolt.GJClient;
  #end
  
  class Example extends FlxUIState
  {
    override function create()
    {
      super.create();
      
      #if desktop
      GJClient.initialize();
      #end
    }
  }
  ```

## Still have doubts about its use?
If you're still have questions about how to use this client correctly,
you're free to talk to me by [Twitter](https://twitter.com/GamerPablito1) or Discord (GamerPablito#3132)

You can also check out my [Youtube Channel](https://www.youtube.com/channel/UCpavbRRdISmsF_fpiAuVafg),
where I'll be uploading everything related to this project and more stuff :)

## Special Thanks
- [EyeDaleHim](https://github.com/EyeDaleHim) : For suggest me about a better command for printing responses