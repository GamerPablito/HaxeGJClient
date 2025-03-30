package gamejolt;

/**
 * The GameJolt API Class where the global values for `GJRequest` instances are setted up.
 * @see For more info about the GameJolt API and calls: https://gamejolt.com/game-api
 */
class GameJolt {
	/**
	 * Your Game ID goes here.
	 */
	public static var gameID:Int = 0;

	/**
	 * Your Game Private Key goes here.
	 */
	public static var gameKey:String = "";

	/**
	 * If `true`, `GJRequest` instances will use `Md5` encryptation for request calls.
	 * Otherwise, they'll use `Sha1` encryptation instead.
	 */
	public static var usingMd5:Bool = true;

	/**
	 * The Username of the user.
	 */
	public static var userName:String = "";

	/**
	 * The Game Token of the user. \
	 * NOTE: If you leave this `null`, only the functions related to Scores are gonna be functional for the user. \
	 */
	public static var userToken:String = "";
}
