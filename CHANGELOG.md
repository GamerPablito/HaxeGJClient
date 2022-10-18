# GameJolt Client Changelog

## V1.2
- Now the commands are processed under the current GameJolt API Version (v1.2, no longer v1.0)
- Auto-Login option implanted (now you can choose if you want or not to be logged in the game automatically when the game opens)
- Global rank feature added
- Scores format support implanted
- Some command descriptions were polished
- The tracing commands of response were re-arranged and called by `Sys.printLn()` instead of `trace()` (Thanks @EyeDaleHim for the suggestion)

## V1.1
- The `checkSessionActive()` function was repaired successfully
- Game Data can now be privatized (Check out the [README](README.md) to know how!)
- URL Constructions rearranged to fix other minor issues

## V1.0
- URL construction for requests now contains the common vars in its scripting
- Users format support implanted
- Trophies format support implanted
- Each command now has their own source of info containment
- Commands only run if a session is active, to avoid bugs
- User Data Storage in FlxG.save.data vars for auto-login to the game
- Minor bugfixes
