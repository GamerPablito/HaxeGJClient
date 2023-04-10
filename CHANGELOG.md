# Haxe GameJolt Client Changelog

## V1.6
- PFP Images for Users are now supported through some OpenFL tools (check `userGraphics` variable for more info)
- The `logged` variable can now be auto-updated every time it's used, so you can check your login state in real-time
- Now parameters (internal ones) are callable by a Map of Strings instead of an Array of String Arrays

## V1.5
- Code re-arrangement with the help of the `.vscode` files
- Instructions in README file were finally fixed out
- Now data types are inside the `GJClient.hx` file, no longer in separated files
- Gramatical mistake ("trophie" to "trophy") were corrected successfully
- Added a Template for `GJKeys.hx` file, so you know what to do with it and how
- Added a `showMessages` variable, this in order to let the user toggle the console messages
- The variable `logged` is now a read-only variable, so no one can alter its value in any way
- Errors are now shown in a special way, separated from the custom messages for each command
- The function `getScoresList()` had a re-arrangement of its parameters
- Some useless variables were removed in some functions to keep CPU memory's sake

## V1.4
- Removed `checkSessionActive()` function
- Removed Auto-Login stuff
- URL Construction was improved to throw data and errors correctly
- The function `pingSession()` was improved and fixed successfully.
- Functions `hasLoginInfo()` and `hasGameInfo()` are now public for their use in-game
- The README file now includes better explanations about its use (info and example coding lines)

## V1.3
- Friend list command implanted
- The URL Construction no longer contains the useless return variables for functions (success:Bool and error:String), they've been quitted cuz there's no use for them
- Some functions that make actions using any of the formats created will return respective data with a `Dynamic -> Void` function according the format for the action, this is for creative purposes
- The function `getUserInfo()` was repaired and modified successfully, this in order to be adapted to the new friend list command
- Instructions for many commands have been polished and updated with the changes mentioned above
- Some params in the Score format were signalized as null, this in order to get the information that's really needed for the new functions arrange
- New commands to detect if there's no data to fetch (game or user)
- New console printing system for commands (`printMsg()`)
- Many issues were repaired

## V1.2
- Now the commands are processed under the current GameJolt API Version (v1.2, no longer v1.0)
- Now you can choose if you want to use `Md5` or `Sha1` encriptation for the command processing
- Auto-Login option implanted (now you can choose if you want or not to be logged in the game automatically when the game opens)
- Global rank feature added
- Scores format support implanted
- Some command descriptions were polished
- Some of the commands now return the new data fetched instead of the success state, this in order to make the new data received for creative purposes
- The tracing commands of response were re-arranged and called by `Sys.printLn()` instead of `trace()` (Thanks EyeDaleHim for the suggestion)

## V1.1
- The `checkSessionActive()` function was repaired successfully
- Game Data can now be privatized
- URL Constructions rearranged to fix other minor issues

## V1.0
- URL construction for requests now contains the common vars in its scripting
- Users format support implanted
- Trophies format support implanted
- Each command now has their own source of info containment
- Commands only run if a session is active, to avoid bugs
- User Data Storage in FlxG.save.data vars for auto-login to the game
- Minor bugfixes
