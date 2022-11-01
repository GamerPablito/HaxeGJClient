# GameJolt Client Changelog

## V1.3
- Friend list command implanted
- The URL Construction no longer contains the useless return variables for functions (success:Bool and error:String), they've been quitted cuz there's no use for them
- Some functions that make actions using any of the formats created will return respective data with a "Dynamic -> Void" function according the format for the action, this is for creative purposes
- The `getUserInfo()` function was repaired and modified successfully, this in order to be adapted to the new friend list command
- Instructions for many commands have been polished and updated with the changes mentioned above
- Some params in the [Score](gamejolt/formats/Score.hx) format were signalized as null, this in order to get the information that's really needed for the new functions arrange
- New commands to detect if there's no data to fetch (game or user)
- New console printing system for commands (`printMsg()`)
- Many issues were repaired

## V1.2
- Now the commands are processed under the current GameJolt API Version (v1.2, no longer v1.0)
- Now you can choose if you want to use `Md5` or `Sha1` encriptation for the command processing
- Auto-Login option implanted (now you can choose if you want or not to be logged in the game automatically when the game opens)
- Global rank feature added
- [Scores](gamejolt/formats/Score.hx) format support implanted
- Some command descriptions were polished
- Some of the commands now return the new data fetched instead of the success state, this in order to make the new data received for creative purposes
- The tracing commands of response were re-arranged and called by `Sys.printLn()` instead of `trace()` (Thanks [EyeDaleHim](https://github.com/EyeDaleHim) for the suggestion)

## V1.1
- The `checkSessionActive()` function was repaired successfully
- Game Data can now be privatized (Check out the [README](README.md) to know how!)
- URL Constructions rearranged to fix other minor issues

## V1.0
- URL construction for requests now contains the common vars in its scripting
- [Users](gamejolt/formats/User.hx) format support implanted
- [Trophies](gamejolt/formats/Trophie.hx) format support implanted
- Each command now has their own source of info containment
- Commands only run if a session is active, to avoid bugs
- User Data Storage in FlxG.save.data vars for auto-login to the game
- Minor bugfixes
