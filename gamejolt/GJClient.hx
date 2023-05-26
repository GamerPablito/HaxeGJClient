package gamejolt;

import flixel.FlxG;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.Bytes;

using StringTools;

/**
 * The way the scores are fetched from your game API.
 * 
 * @param score The stringified Score.
 * @param sort The value of the Score.
 * @param extra_data Extra data about the Score.
 * @param user The username of the User who reached this Score (if it's a registered User).
 * @param user_id The ID of the User who reached this Score (if it's a registered User).
 * @param guest The "guest" name of the User who reached this Score (if it's NOT a registered User).
 * @param stored A short description about the date the User reached this Score (if it's a registered User).
 * @param stored_timestamp A long time stamp (in seconds) of the date the User reached this Score (if it's a registered User).
 */
typedef Score = {
	score:String,
	sort:Int,
	extra_data:String,
	?user:String,
	?user_id:Int,
	?guest:String,
	?stored:String,
	?stored_timestamp:Int
}

/**
 * The way the trophies are fetched from your game API.
 * 
 * @param id The ID of the Trophy.
 * @param title The title of the Trophy.
 * @param description The description of the Trophy.
 * @param difficulty The difficulty rank of the Trophy.
 * @param image_url The link of the image that represents the Trophy.
 * @param achieved Whether this Trophy was achieved or not, it can be a string if it was (with info about how much time ago it was achieved) or bool if not (false).
 */
typedef Trophy = {
	id:Int,
	title:String,
	description:String,
	difficulty:String,
	image_url:String,
	achieved:Dynamic
}

/**
 * The way the user data is fetched from the GameJolt API.
 * Only works with registered users.
 * 
 * @param id The ID of the User.
 * @param type The cathegory the User is cataloged like in GameJolt.
 * @param username The username of the User.
 * @param avatar_url The link of the avatar of the User.
 * @param signed_up A short description about how long the User have been in GameJolt.
 * @param signed_up_timestamp A long time stamp (in seconds) of when the User signed up.
 * @param last_logged_in A short description about the last time the User was found active in GameJolt.
 * @param last_logged_in_timestamp A long time stamp (in seconds) of the last time the User logged in GameJolt.
 * @param status The actual status of the User.
 * @param developer_name The display name of the User.
 * @param developer_website The website of the User.
 * @param developer_description The description of the User.
 */
typedef User = {
	id:Int,
	type:String,
	username:String,
	avatar_url:String,
	signed_up:String,
	signed_up_timestamp:Int,
	last_logged_in:String,
	last_logged_in_timestamp:Int,
	status:String,
	developer_name:String,
	developer_website:String,
	developer_description:String
}

/**
 * A completely original GameJolt Client made by [GamerPablito](https://https://twitter.com/GamerPablito1)
 * using some tools from Haxe, Lime and Flixel to gather info from the GameJolt API with ease.
 * 
 * No extra extensions required at all!
 * 
 * Originally made for the game Friday Night Funkin', but it can also be used for every game made with HaxeFlixel.
 * 
 * ## Commands Usage
 * - Almost every function here will return a `Future` instance with a certain kind of value on it. \
 *   These instances work with these functions:
 * 	- ### Function "onComplete":
 * 		With the `onComplete()` function you can set actions to execute if the process
 * 		finishes successfully with a variable holding the data the `Future` loads.
 * 		```haxe
 * 		// This is a "Future" instance (Replace "T" with your prefered type)
 * 		var daFuture:Future<T> = justATestFunc(); 
 * 		// Returns a value with the type defined in the "Future" instance if the process finished successfully
 * 		// You can use the value as its "T" type into your actions for other creative purposes depending of the function!
 * 		daFuture.onComplete(function(daValue:T) {trace(daValue);}); // "daValue" is a "T" type variable
 * 		```
 * 	- ### Function "onProgress":
 * 		With the `onProgress()` function you can set actions to execute while the "Future"
 * 		does its thing. It can be used to make loading screens or related stuff since this counts
 * 		with 2 variables representing the current progress of the "Future" process.
 * 		```haxe
 * 		// Here you can set up an `(Int, Int) -> Void` function
 * 		// The first variable is the progress value and second variable is the final value.
 * 		// In this case, all the final values will return "100"
 * 		// And the progress values will be rounded percentage values related to it
 * 		daFuture.onProgress(function(progress:Int, total:Int) {trace("Progress: " + progress + "/" + total);});
 * 		```
 * 	- ### Function "onError":
 * 		With the `onError()` function you can set actions to execute if the "Future"
 * 		failed to load its respective data, it also returns the error description into a dynamic variable
 * 		```haxe
 * 		// If you're about to use the error value as string, better for you to use "Std.string(e)"
 * 		daFuture.onError(function(e:Dynamic) {trace("Error: " + e);});
 * 		```
 */
class GJClient {
	/*
		----------------------------------------------------------------
		-------------> GUI = GameJolt User Information <------------------
		--> EVERY COMMAND HERE WILL WORK ONLY IF GUI PARAMETERS EXIST!! <--
		----------------------------------------------------------------
	 */
	/**
	 * Tells you if some GUI already exists in the game app or not.
	 * @return Is it available?
	 */
	public static function hasLoginInfo():Bool
		return getUser() != null && getToken() != null;

	/**
	 * Tells you if the GameJolt info about your game is available or not.
	 * @return Is it available?
	 */
	public static function hasGameInfo():Bool
		return GJKeys.id != 0 && GJKeys.key != '';

	/**
	 * If `true`, functions will use `Md5` encriptation for data processing; if `false`, they'll use `Sha1` encriptation instead.
	 */
	public static var useMd5:Bool = true;

	/**
	 * Sets a new GUI in the database, the Username and the Game Token of the player respectively. \
	 * You can use this before use `login()` or `logout()`, since they use the data setted through here.
	 * 
	 * @param user The new Username of the Player.
	 * @param token The new Game Token of the Player.
	 * @return A `Future` instance with a `Bool` result of the process.
	 * 			**(`Bool` = Whether if process was completed but also successful or not)**
	 */
	public static function setUserInfo(user:Null<String>, token:Null<String>):Future<Bool> {
		var temp_user = getUser();
		var temp_token = getToken();

		if (user == '')
			user = null;
		if (token == '')
			token = null;

		function resetOldData() {
			FlxG.save.data.gjUser = temp_user;
			FlxG.save.data.gjToken = temp_token;
		}

		logout();

		var daPromise:Promise<Bool> = new Promise<Bool>();
		if (user != null && token != null) {
			FlxG.save.data.gjUser = user;
			FlxG.save.data.gjToken = token;

			var newAuth = authUser();
			newAuth.onComplete(function(success) {
				if (!success)
					resetOldData();

				daPromise.complete(success);
			});
			newAuth.onProgress((p, f) -> daPromise.progress(p, f));
			newAuth.onError(function(e) {
				resetOldData();
				daPromise.error(e);
			});
		} else {
			FlxG.save.data.gjUser = FlxG.save.data.gjToken = null;
			daPromise.complete(true);
		}

		return daPromise.future;
	}

	/**
	 * Returns the information of any user in GameJolt, according to the ID inserted.
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @param id The ID of the user to fetch the info from (leave `null` if you wanna fetch the info from the actual user logged in).
	 * @return A `Future` instance with an `User` result of the process.
	 * 			**(`User` = The user info, if process was successfully finished)**
	 */
	public static function getUserData(?id:Int):Future<User> {
		var daPromise:Promise<User> = new Promise<User>();
		var process = urlConstruct('users', null, id != null ? ['user_id' => Std.string(id)] : null, id == null, false);
		process.onComplete(function(data) {
			var daUser:User = cast data.users[0];
			var newUrl:String = daUser.avatar_url.substring(0, 32);
			newUrl += '1000';
			newUrl += daUser.avatar_url.substr(34);
			newUrl = newUrl.replace(".jpg", ".png");
			daUser.avatar_url = newUrl;
			daPromise.complete(daUser);
		});
		process.onProgress((p, f) -> daPromise.progress(p, f));
		process.onError(e -> daPromise.error('Failed to fetch user data -> $e'));
		return daPromise.future;
	}

	/**
	 * Throws the friend list of the user that's actually logged in. \
	 * Not only that, it will throw the individual info of every friend that's fetched here!
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @return A `Future` instance with an `Array<User>` result of the process.
	 * 			**(`Array<User>` = An array with the info of all the user's friends, if process was successfully finished)**
	 */
	public static function getFriendsList():Future<Array<User>> {
		var daPromise:Promise<Array<User>> = new Promise<Array<User>>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (isLogged) {
				var process = urlConstruct('friends');
				process.onComplete(function(data) {
					var list:Array<Dynamic> = data.friends;
					var friends:Array<User> = [];

					for (person in list) {
						if (daPromise.isError)
							break;

						var fetchPerson = getUserData(Std.int(person.friend_id));
						fetchPerson.onComplete(function(user) {
							friends.push(user);
							daPromise.progress(Std.int((friends.length / list.length) * 100), 100);
							if (friends.length == list.length)
								daPromise.complete(friends);
						});
						fetchPerson.onError((e) -> daPromise.error('Failed to fetch friend info -> $e'));
					}
				});
				process.onError(e -> daPromise.error('Failed to load friend list -> $e'));
			} else
				daPromise.error('There is no session active to load friend list from');
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Fetches all the trophies available in your game, all the trophies will have their own data formatted in .json. \
	 * It also tells you if you've already achieved them or not. Very useful if you're making a Trophy screen or smth related.
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @param achievedOnes  Whether you want the list to be only with achieved trophies (`true`) or unachived trophies (`false`).
	 *                        Leave `null` if you want to see all the trophies no matter if they're achieved or not.
	 * @return A `Future` instance with an `Array<Trophy>` result of the process.
	 * 			**(`Array<Trophy>` = The list of the specified trophies from the game and their states according the user logged in,
	 * 			if process was successfully finished)**
	 */
	public static function getTrophiesList(?achievedOnes:Bool):Future<Array<Trophy>> {
		var daPromise:Promise<Array<Trophy>> = new Promise<Array<Trophy>>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (isLogged) {
				var process = urlConstruct('trophies', null, achievedOnes != null ? ['achieved' => Std.string(achievedOnes)] : null);
				process.onComplete(function(data) {
					var trophList:Array<Trophy> = data.trophies;
					var count:Int = 0;

					for (t in trophList) {
						var newUrl:String = "";
						if (t.image_url.startsWith('https://m.')) {
							newUrl = t.image_url.substring(0, 37);
							newUrl += '1000';
							newUrl += t.image_url.substr(40);
							newUrl = newUrl.replace(".jpg", ".png");
						} else {
							newUrl = "https://s.gjcdn.net/assets/";
							switch (t.image_url.substring(24).replace('.jpg', '')) {
								case "trophy-bronze-1":
									newUrl += "9c2c91d0.png";
								case "trophy-silver-1":
									newUrl += "b46e352e.png";
								case "trophy-gold-1":
									newUrl += "363ce2dc.png";
								case "trophy-platinum-1":
									newUrl += "92e5330d.png";
								default:
							}
						}
						t.image_url = newUrl;
						count++;
						daPromise.progress(Std.int((count / trophList.length) * 100), 100);
					}
					daPromise.complete(trophList);
				});
				process.onError(e -> daPromise.error('Failed to fetch trophies list -> $e'));
			} else
				daPromise.error('There is no session active to fetch trophies list from');
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Gives a Trophy from the game to the actual user logged in!
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @param id The ID of the Trophy to achieve.
	 * @return A `Future` instance with a `Trophy` result of the process.
	 * 			**(`Trophy` = The data from the achieved trophy, if process was successfully finished)**
	 */
	public static function trophyAdd(id:Int):Future<Trophy> {
		var daPromise:Promise<Trophy> = new Promise<Trophy>();
		var trophies = getTrophiesList();

		trophies.onComplete(function(list) {
			for (t in list)
				if (t.id == id) {
					var process = urlConstruct('trophies', 'add-achieved', ['trophy_id' => Std.string(id)]);
					process.onComplete(data -> daPromise.complete(t));
					process.onProgress((p, f) -> daPromise.progress(p, f));
					process.onError(e -> daPromise.error('Failed to add a trophy to the user -> $e'));
					return;
				}

			daPromise.error('Invalid ID for trophie addition');
		});

		trophies.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Removes a Trophy of the game from the actual user logged in. (Useful in case it was achieved by cheating or just for test it out!)
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @param id The ID of the Trophy to remove.
	 * @return A `Future` instance with a `Trophy` result of the process.
	 * 			**(`Trophy` = The data from the removed trophy, if process was successfully finished)**
	 */
	public static function trophyRemove(id:Int):Future<Trophy> {
		var daPromise:Promise<Trophy> = new Promise<Trophy>();
		var trophies = getTrophiesList();
		trophies.onComplete(function(list) {
			for (t in list)
				if (t.id == id) {
					var process = urlConstruct('trophies', 'remove-achieved', ['trophy_id' => Std.string(id)]);
					process.onComplete(data -> daPromise.complete(t));
					process.onProgress((p, f) -> daPromise.progress(p, f));
					process.onError(e -> daPromise.error('Failed to remove a trophy from the user -> $e'));
					return;
				}

			daPromise.error('Invalid ID for trophie removal');
		});
		trophies.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Fetches all the scores submitted on a score table in your game, all the scores will have their own data formatted in .json. \
	 * You can also set if you want to fetch the scores in the table from the actual user or from the game in general!
	 * @see The `formats` folder, to get more info about how formats are setted like.
	 * @param fromUser This is where you can set if you want to fetch scores from the actual logged user only (`true`), or from the game itself (`false`)
	 * @param table_id The score Table ID where the scores will be fetched from (if `null`, the scores will be fetched from the "Primary" score table in your game)
	 * @param delimiter If you want to fetch the scores that are major or minor than a certain value, set it here, otherwise leave in blank.
	 * @param limit The number of scores to return. Must be a number between 1 and 100 (Default: 10).
	 *                    (Note: If you want the scores that are ABOVE the value, set it in POSITIVE, but
	 *                     if you want the scores that are BELOW the value, set it in NEGATIVE)
	 * @return A `Future` instance with an `Array<Score>` result of the process.
	 * 			**(`Array<Score>` = The list of the scores obtained according the parameters, if process was successfully finished)**
	 */
	public static function getScoresList(fromUser:Bool, ?table_id:Int, ?delimiter:Int, limit:Int = 10):Future<Array<Score>> {
		var daPromise:Promise<Array<Score>> = new Promise<Array<Score>>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if ((isLogged && fromUser) || !fromUser) {
				var daParams:Map<String, String> = [];

				if (table_id != null)
					daParams.set('table_id', Std.string(table_id));
				if (delimiter != null)
					daParams.set(delimiter >= 0 ? 'better_than' : 'worse_than', Std.string(Math.abs(delimiter)));

				if (limit <= 0)
					limit = 1;
				if (limit > 100)
					limit = 100;
				if (limit != 10)
					daParams.set('limit', Std.string(limit));

				var process = urlConstruct('scores', null, daParams, fromUser, fromUser);
				process.onComplete(data -> daPromise.complete(data.scores));
				process.onProgress((p, f) -> daPromise.progress(p, f));
				process.onError(e -> daPromise.error('Failed to reach scores list -> $e'));
			} else
				daPromise.error('There is no session active to get score lists from');
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Submits a new score made by the actual logged user to a specified score table in your game!
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @param score_content The stringified version of the score. Example: 500 jumps.
	 * @param score_value The score itself. Example: 500.
	 * @param extraInfo If you want to, you can give extra information about how the score was obtained,
	 *                    useful to make game developers know if the player obtained that score legally, but this is completely optional.
	 * @param table_id The score table ID where the new score will be submitted to (if `null`, the score will be submitted from the "Primary" score table in your game).
	 * @return A `Future` instance with a `Score` result of the process.
	 * 			**(`Score` = The data of the score submitted, if process was successfully finished)**
	 */
	public static function submitNewScore(score_content:String, score_value:Int, ?extraInfo:String, ?table_id:Int):Future<Score> {
		var daPromise:Promise<Score> = new Promise<Score>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (isLogged) {
				var daParams:Map<String, String> = ['score' => score_content, 'sort' => Std.string(score_value)];

				if (extraInfo != null)
					daParams.set('extra_data', extraInfo);
				if (table_id != null)
					daParams.set('table_id', Std.string(table_id));

				var process = urlConstruct('scores', 'add', daParams);
				process.onComplete(data -> daPromise.complete({
					score: score_content,
					sort: score_value,
					extra_data: extraInfo != null ? extraInfo : '',
				}));
				process.onProgress((p, f) -> daPromise.progress(p, f));
				process.onError(e -> daPromise.error('Failed to submit a new score -> $e'));
			} else
				daPromise.error('There is no session active to set new score to');
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Gives you the global rank you got in a certain score table in your game. \
	 * This is given according to the top score you have in that table.
	 * @param table_id The score sable ID where the rank will be obtained from (if `null`, the rank will be given from the "Primary" score table in your game).
	 * @return A `Future` instance with an `Int` result of the process.
	 * 			**(`Int` = Global score rank of the specified table, if process was successfully finished)**
	 */
	public static function getGlobalRank(?table_id:Int):Future<Int> {
		var daPromise:Promise<Int> = new Promise<Int>();
		var scores = getScoresList(true, table_id, null, 1);
		scores.onComplete(function(list) {
			var daParams:Map<String, String> = ['sort' => Std.string(list[0].sort)];
			if (table_id != null)
				daParams.set('table_id', Std.string(table_id));

			var process = urlConstruct('scores', 'get-rank', daParams, false, false);
			process.onComplete(data -> daPromise.complete(Std.int(data.rank)));
			process.onProgress((p, f) -> daPromise.progress(p, f));
			process.onError(e -> daPromise.error('Failed to fetch global rank from the score table -> $e'));
		});
		scores.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * This will open your GameJolt session. \n
	 * Useful for open a new session when a new GUI is setted by `setUserInfo()`,
	 * or if you closed your session by decision of yours (without erasing your GUI,
	 * use only `logout()`, otherwise use `setUserInfo()` with null or empty parameters instead).
	 * @see The `typedef` classes defined in this client, to get more info about how formats are fetched like.
	 * @return A `Future` instance with an `User` result of the process.
	 * 			**(`User` = The info of the new user logged in, if process was successfully finished)**
	 */
	public static function login():Future<User> {
		var daPromise:Promise<User> = new Promise<User>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (!isLogged) {
				var process = urlConstruct('sessions', 'open');
				process.onComplete(function(data) {
					var userData = getUserData();
					userData.onComplete(user -> daPromise.complete(user));
					userData.onError(e -> daPromise.error(e));
				});
				process.onProgress((p, f) -> daPromise.progress(p, f));
				process.onError(e -> daPromise.error('Failed to open a new session! -> $e'));
			} else
				daPromise.error('There is an open session already');
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * If there's a session active, this command will log it out. Pretty self-explanatory isn't it? \
	 * But, if you want to log out, but also want to erase your data from the application,
	 * you can use the function `setUserInfo()` with null or empty parameters instead.
	 * @return A `Future` instance with a `Bool` result of the process.
	 * 			**(`Bool` = Whether if process was completed but also successful or not)**
	 */
	public static function logout():Future<Bool> {
		var daPromise:Promise<Bool> = new Promise<Bool>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (isLogged) {
				var process = urlConstruct('sessions', 'close');
				process.onComplete(data -> daPromise.complete(true));
				process.onProgress((p, f) -> daPromise.progress(p, f));
				process.onError(e -> daPromise.error('Failed to close the current session! -> $e'));
			} else
				daPromise.complete(false);
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * If there's a session active, this function keeps the session active,
	 * so it needs to be placed in somewhere it can be executed repeatedly.
	 * @return A `Future` instance with a `Bool` result of the process.
	 * 			**(`Bool` = Whether if process was completed but also successful or not)**
	 */
	public static function pingSession():Future<Bool> {
		var daPromise:Promise<Bool> = new Promise<Bool>();
		var logged = checkLogin();
		logged.onComplete(function(isLogged) {
			if (isLogged) {
				var process = urlConstruct('sessions', 'ping');
				process.onComplete(data -> daPromise.complete(true));
				process.onProgress((p, f) -> daPromise.progress(p, f));
				process.onError(e -> daPromise.error('Failed to make a ping for the current session -> $e'));
			} else
				daPromise.complete(false);
		});
		logged.onError(e -> daPromise.error(e));
		return daPromise.future;
	}

	/**
	 * Tells you if you're currently in session with this game or not.
	 * @return A `Future` instance with a `Bool` result of the process.
	 * 			**(`Bool` = Whether if there's a session active in the game with the registered user or nor)**
	 */
	public static function checkLogin():Future<Bool> {
		var daPromise:Promise<Bool> = new Promise<Bool>();
		var process = urlConstruct('sessions', 'check');
		process.onComplete(data -> daPromise.complete(data.success == 'true'));
		process.onProgress((p, f) -> daPromise.progress(p, f));
		process.onError(e -> daPromise.error('Failed to fetch login state -> $e'));
		return daPromise.future;
	}

	// INTERNAL FUNCTIONS (DON'T ALTER IF YOU DON'T KNOW WHAT YOU'RE DOING!!)
	static function urlConstruct(command:String, ?action:String, ?params:Map<String, String>, userAllowed:Bool = true,
			tokenAllowed:Bool = true):Future<Dynamic> {
		var daPromise:Promise<Dynamic> = new Promise<Dynamic>();

		if (hasLoginInfo() && hasGameInfo()) {
			var mainURL:String = "http://api.gamejolt.com/api/game/v1_2/";
			mainURL += '$command${action != '' ? '/$action' : ''}';
			mainURL += '/?game_id=${Std.string(GJKeys.id)}';

			if (userAllowed)
				mainURL += '&username=${getUser()}';
			if (tokenAllowed)
				mainURL += '&user_token=${getToken()}';
			if (params != null)
				for (k => v in params)
					mainURL += '&$k=$v';

			var daEncode:String = mainURL + GJKeys.key;
			mainURL += '&signature=${useMd5 ? Md5.encode(daEncode) : Sha1.encode(daEncode)}';

			var daFuture:Future<Bytes> = Bytes.loadFromFile(mainURL);
			daFuture.onComplete(function(bdata) {
				var daValue:Dynamic = cast Json.parse(bdata.toString()).response;
				if (daValue.message == null)
					daPromise.complete(daValue);
				else
					daPromise.error(daValue.message);
			});
			daFuture.onProgress((p, f) -> daPromise.progress(Std.int((p / f) * 100), 100));
			daFuture.onError(e -> daPromise.error(e));
		} else
			daPromise.error('Missing or wrong Game Info or User info for URL request');

		return daPromise.future;
	}

	static function authUser():Future<Bool> {
		var daPromise:Promise<Bool> = new Promise<Bool>();
		var process = urlConstruct('users', 'auth');
		process.onComplete(data -> daPromise.complete(data.success == 'true'));
		process.onProgress((p, f) -> daPromise.progress(p, f));
		process.onError(e -> daPromise.error('Failed to authenticate incoming user data -> $e'));
		return daPromise.future;
	}

	static function getUser():Null<String>
		return FlxG.save.data.gjUser;

	static function getToken():Null<String>
		return FlxG.save.data.gjToken;
}
