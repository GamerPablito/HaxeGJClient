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
  - `crypto.Md5` (used to encript a special signature to access the API in a safe way)
- This client is totally independient, it doesn't requires any extra GameJolt libraries to work, cuz everything is written and composed here
- This also contains some files with info formats about how some data has to be received like, this in order to let the user know how to use the data in their game
- Every file is full of instructions for each command, in order to do the things right if you don't know so much about it

## How to Use in Game
1. Download this repository
2. Copy the `gamejolt` folder into the `source` folder of your game
3. Go to the `GJClient.hx` and setup the `gameID` and `gamePrivKey` vars from your Game GJ Website (if you don't have one, go create one and put the data there)
4. Every time you insert a command from this in some part of your game, make sure its limited by an .xml conditional: "if desktop". Example:
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

## Recommendations/Warnings
- If you need, you can check out the `formats` folder to check every existent format for any kind of use you wanna test out.
- If you want to upload your FNF Mod/Game to GitHub or somewhere else to make it public, make sure to change your `gamePrivKey`
  from your Game GJ Website Database, otherwise your FNF Mod/Game can be hacked by other people.
  You must create a copy of the source code with the new `gamePrivKey` after the change in the website (For Private Use Only)
- You can also check the [changelog](CHANGELOG.md) file to stay tuned about the new changes that comes to this client.

## Still have doubts about its use?
If you're still have questions about how to use this client correctly,
you're free to talk to me by [Twitter](https://twitter.com/GamerPablito1) or Discord (GamerPablito#3132)

You can also check out my [Youtube Channel](https://www.youtube.com/channel/UCpavbRRdISmsF_fpiAuVafg),
where I'll be uploading everything related to this project and more stuff :)
