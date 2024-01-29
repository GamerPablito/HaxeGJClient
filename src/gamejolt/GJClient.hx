package gamejolt;

/**
 * An special class made by [GamerPablito](https://twitter.com/GamerPablito1) to communicate with the GameJolt API of your game with ease.
 * @see The [Wiki Page](https://github.com/GamerPablito/HaxeGJClient/wiki) for more info about GameJolt Calls and such.
 */
final class GJClient
{
	/**
	 * Put you game website API credentials in here, they'll be used by `GJRequest` instances for command creations and calls.
	 */
	public static var apidata:{id:Int, key:String}

	/**
	 * You can manage stuff related with the current User data through here.
	 */
	public static var user(default, null):GJUser;

	/**
	 * You can manage stuff related with the current Game data through here.
	 */
	public static var game(default, null):GJGame;

	public static function init()
	{
		user = new GJUser();
		game = new GJGame();
		apidata = {id: 0, key: ""};
	}
}
