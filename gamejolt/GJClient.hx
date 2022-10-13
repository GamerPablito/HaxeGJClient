package gamejolt;

import flixel.FlxG;
import gamejolt.formats.*;
import haxe.Http;
import haxe.Json;
import haxe.crypto.Md5;

/**
 * A completely original GameJolt Client made by GamerPablito, using Haxe Crypto Encripting and Http tools
 * to gather info about the GameJolt API with ease
 * 
 * Originally made for the game Friday Night Funkin', but it can also be used for every game made with HaxeFlixel
 * 
 * No extra extensions required (except the basic Flixel and Haxe ones)
 */
class GJClient
{
    // Command Title
    static var printPrefix:String = "GameJolt Client:";

    // SET YOUR GAME DATA BEFORE STARTING THIS!!
    static var gameID:String = '';
    static var gamePrivKey:String = '';

    /*
        ----------------------------------------------------------------
        -------------> GUI = GameJolt User Information <------------------
        --> EVERY COMMAND HERE WILL WORK ONLY IF GUI PARAMETERS EXIST!! <--
        ----------------------------------------------------------------
    */

    /**
     * It tells you if you're actually logged in GameJolt (Read only, don't change it!)
     */
    public static var logged:Bool = false;

    /**
     * Sets a new GUI in the database, the Username and the Game Token of the player respectively.
     * This command also closes the previous session (if there was one active) before replace the actual GUI.
     * 
     * If you leave the parameters with an empty string or null, you will be logged out successfully,
     * and you will be able to log in again with other user's GUI.
     * 
     * But if you just wanna log out without erase your GUI from the application, use `logout()` instead.
     * 
     * @param user The Username of the Player.
     * @param token The Game Token of the Player.
     */
    public static function setUserInfo(user:Null<String>, token:Null<String>)
    {

        var temp_user = getUser();
        var temp_token = getToken();

        if (user == '') user = null;
        if (token == '') token = null;

        logout();

        FlxG.save.data.user = user;
        FlxG.save.data.token = token;

        if (hasLoginInfo())
        {
            authUser(
                function (success:Bool)
                {
                    if (success) trace('User GUI parameters were changed: New User -> ${getUser()} | New Token -> ${getToken()}');
                    else
                    {
                        FlxG.save.data.user = temp_user;
                        FlxG.save.data.token = temp_token;
                    }
                },
                function (error:String)
                {
                    FlxG.save.data.user = temp_user;
                    FlxG.save.data.token = temp_token;
                }
            );

            // login();
        }
    }

    /**
     * Run this command to make sure if the actual GUI inserted about a user really exists in GameJolt.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function authUser(?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('users', 'auth'), onSuccess, onFail);
        if (urlData != null) urlData; else return;
    }

    /**
     * If GUI is already setted up in the application, it throws the user data in a .json format.
     * 
     * Very useful if you want to use the actual user's GUI for some parts of your game.
     * 
     * @see The `formats` folder, to get more info about how formats are setted like.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     * @return The GUI in .json format (or null if any data is available in the application to use yet).
     */
    public static function getUserData(?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<User>
    {
        var urlData = urlResult(urlConstruct('users'), onSuccess, onFail);
        var daFormat:Null<User> = urlData != null && logged ? cast urlData.users[0] : null;
        return daFormat;
    }

    /**
     * Fetches all the trophies available in your game,
     * all the trophies will have their own data formatted in .json.
     * 
     * It also tells you if you've already achieved them or not. Very useful if you're making a trophie screen or smth related.
     * 
     * @see The `formats` folder, to get more info about how formats are setted like.
     * 
     * @param achievedOnes  Whether you want the list to be only with achieved trophies or unachived trophies.
     *                        Leave blank if you want to see all the trophies no matter if they're achieved or not.
     *                        If your game doesn't have any trophies in its GameJolt page,
     *                        or doesn't appear according to what you choose in this variable, the result will be `null`.
     * @param onSuccess     Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail         Put a function with actions here, they'll be processed if an error has ocurred during the process.
     * @return The array with all the trophies of the game in .json format (or null if there's no GUI inserted in the application yet).
     */
    public static function getTrophiesList(?achievedOnes:Bool, ?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<Array<Trophie>>
    {
        var daParam:Null<Array<Array<String>>> = achievedOnes != null ? [['achieved', Std.string(achievedOnes)]] : null;
        var urlData = urlResult(urlConstruct('trophies', null, daParam), onSuccess, onFail);
        var daFormat:Null<Array<Trophie>> = urlData != null && logged ? urlData.trophies : null;
        return daFormat;
    }

    /**
     * Gives a trophie from the game to the actual user logged in!
     * 
     * Won't do anything if you're not logged so don't worry, the game won't crash.
     * 
     * @param id The ID of the trophie to achieve (Required)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function trophieAdd(id:Int, ?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var daList = getTrophiesList();

        if (logged && daList != null)
        {
            var urlData = urlResult(urlConstruct('trophies', 'add-achieved', [['trophy_id', Std.string(id)]]),
            function (data:Bool)
            {
                for (troph in 0...daList.length)
                {
                    if (daList[troph].id == id)
                    {
                        if (daList[troph].achieved == false)
                        {
                            trace('$printPrefix The trophie "${daList[troph].title}" (Trophie ID: $id) has been achieved by ${getUser()}');
                            if (onSuccess != null) onSuccess(data);
                        }
                        else trace('$printPrefix The trophie "${daList[troph].title}" (Trophie ID: $id) is already achieved by ${getUser()}');
                        break;
                    }
                }
            },
            function (error:String)
            {
                trace('$printPrefix The trophie ID "$id" was not found in the game database!');
                if (onFail != null) onFail(error);
            });
            if (urlData != null) urlData;   
        }
    }

    /**
     * Removes a trophie of the game from the actual user logged in. Useful in case it was achieved by cheating or just for test it out!
     * 
     * Won't do anything if you're not logged so don't worry, the game won't crash.
     * 
     * @param id The ID of the trophie to remove (Required)
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function trophieRemove(id:Int, ?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var daList = getTrophiesList();

        if (logged && daList != null)
        {
            var urlData = urlResult(urlConstruct('trophies', 'remove-achieved', [['trophy_id', Std.string(id)]]),
            function (data:Bool)
            {
                for (troph in 0...daList.length)
                {
                    if (daList[troph].id == id)
                    {
                        if (daList[troph].achieved == false)
                        {
                            trace('$printPrefix The trophie "${daList[troph].title}" (Trophie ID: $id) has been quitted from ${getUser()}');
                            if (onSuccess != null) onSuccess(data);
                        }
                        else trace('$printPrefix The trophie "${daList[troph].title}" (Trophie ID: $id) is not achieved by ${getUser()} yet.');
                        break;
                    }
                }
            },
            function (error:String)
            {
                trace('$printPrefix The trophie ID "$id" was not found in the game database!');
                if (onFail != null) onFail(error);
            });
            if (urlData != null) urlData;   
        }
    }

    /**
     * This will open your GameJolt session.
     * 
     * Useful for re-open a session when a new GUI is setted by `setUserInfo()`,
     * or if you closed your session by decision of yours (without erasing your GUI, using `logout()`, otherwise re-use `setUserInfo()`).
     * 
     * (Do not compare with the `initialize()` function)
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function login(?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'open'),
        function (data:Bool)
        {
            if (!logged) trace('$printPrefix Logged in successfully!');
            if (onSuccess != null && !logged) onSuccess(data);
            logged = true;
        },
        onFail);
        if (urlData != null && !logged) urlData; else return;
    }

    /**
     * If there's a session active, this command will log it out. Pretty self-explanatory isn't it?
     * 
     * But, if you want to log out, but also want to erase your data from the application,
     * you can use the function `setUserInfo()` with null or empty parameters.
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process. 
     */
    public static function logout(?onSuccess:Bool -> Void, ?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'close'),
        function (data:Bool)
        {
            if (logged) trace('$printPrefix Logged out successfully!');
            if (onSuccess != null && logged) onSuccess(data);
            logged = false;
        },
        onFail);
        if (logged && urlData != null) urlData; else return;
    }

    /**
     * If there's a session active, this function keeps the session active, so it needs to be placed in somewhere it can be executed repeatedly.
     * 
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.  
     */
    public static function pingSession(?onFail:String -> Void)
    {
        var urlData = urlResult(urlConstruct('sessions', 'ping'),
        function (pinged:Bool)
        {
            trace('$printPrefix Session pinged!');
        },
        function (error:String)
        {
            if (logged)
            {
                trace('$printPrefix Ping failed! You\'ve been disconnected!');
                if (onFail != null) onFail(error);
            }
            logged = false;
        });
        if (logged && urlData != null) urlData; else return;
    }

    /**
     * Tells you if there's a section active or not!
     * 
     * This is mostly used for confirmation, cuz the client works with the
     * variable `logged` instead of this command for a better performance.
     */
    public static function checkSessionActive():Bool
    {
        var result:Bool = false;
        var urlData = urlResult(urlConstruct('sessions', 'check'),
        function (isActive:Bool)
        {
            trace('$printPrefix Is a session active? : $isActive');
            result = logged = isActive;
        });
        if (urlData != null && logged) urlData;
        return result;
    }

    /**
     * This initialize the client in general.
     * It opens your session ans sync your data according to the saved GUI data for a better experience when the user comes back.
     * 
     * (Do not compare with the `login()` function)
     * 
     * @param onSuccess Put a function with actions here, they'll be processed if the process finish successfully.
     * @param onFail Put a function with actions here, they'll be processed if an error has ocurred during the process.
     */
    public static function initialize(?onSuccess:() -> Void, ?onFail:() -> Void)
    {
        if (hasLoginInfo() && !logged)
        {
            authUser(function (success1:Bool)
            {
                trace('$printPrefix User authenticated successfully!');

                login(function (success2:Bool)
                {
                    if (!logged)
                    {
                        trace('$printPrefix Session Opened! User: ${getUser()}, Token: ${getToken()}');
                        if (onSuccess != null) onSuccess();
                    }
                    logged = true;
                },
                function (error2:String)
                {
                    trace('$printPrefix Login process failed!');
                    if (onFail != null) onFail();
                });
            },
            function (error1:String)
            {
                trace('$printPrefix User authentication failed!');
                if (onFail != null) onFail();
            });
        }
    }

    // INTERNAL FUNCTIONS (DON'T ALTER IF YOU DON'T KNOW WHAT YOU'RE DOING!!)

    static function hasLoginInfo():Bool
    {
        return getUser() != null && getToken() != null;
    }

    static function urlConstruct(command:String, ?action:String, ?params:Array<Array<String>>):Null<Http>
    {
        if (hasLoginInfo())
        {
            var mainURL:String = "http://api.gamejolt.com/api/game/v1_1/";

            mainURL += command;
            mainURL += '/' + (action != null ? '$action/?' : '?');
    
            mainURL += 'game_id=${gameID}&';
            mainURL += 'username=${getUser()}&';
            mainURL += 'user_token=${getToken()}';
    
            if (params != null) {for (pars in params) mainURL += '&${pars[0]}=${pars[1]}';}
    
            mainURL += '&signature=${Md5.encode(mainURL + gamePrivKey)}';
    
            return new Http(mainURL);
        }

        return null;
    }

    static function urlResult(daUrl:Null<Http>, ?onSuccess:Bool -> Void, ?onFail:String -> Void):Null<Dynamic>
    {
        var result:String = '';
        var success:Bool = false;

        if (daUrl != null)
        {
            daUrl.onData = function (data:String)
            {
                result = data;
                success = Json.parse(data).response.success == 'true';
                if (onSuccess != null) onSuccess(success);
            };
            daUrl.onError = function (error:String) {if (onFail != null) onFail(error);};
            daUrl.request(false);
        }

        return success ? Json.parse(result).response : null;
    }

    static function getUser():Null<String> {return FlxG.save.data.user;}
    static function getToken():Null<String> {return FlxG.save.data.token;}
}