package;

import flixel.util.typeLimit.OneOfTwo;
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import lime.app.Application;
import lime.app.Future;
import lime.app.Promise;
import sys.thread.Thread;

using StringTools;

typedef Response = {
	// General
	success:String,
	?message:String,
	// User Fetching
	?users:Array<User>,
	// Scores Fetching
	?trophies:Array<Trophy>,
	// Friends Fetching
	?friends:Array<{friend_id:Int}>,
	// Data Store Fetching
	?keys:Array<{key:String}>,
	?data:String
}

/**
 * When there's a session active, data is loaded using this formatted here,
 * so you don't have to make repetitive requests just to get the same data all the time.
 * 
 * @param info Information data about the current user logged in.
 * @param friends Friends List from the current user logged in.
 * @param trophies Trophies List and their state according to the data from the current user logged in.
 * @param data Information saved in the game's data store about the current user logged in.
 */
typedef Session = {
	info:User,
	friends:Array<User>,
	trophies:Array<Trophy>,
	data:Map<String, IntOrString>
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
	achieved:String
}

/**
 * An enum class to clasify Data Store update functions
 */
enum DataUpdateType {
	Add(n:Int);
	Substract(n:Int);
	Multiply(n:Int);
	Divide(n:Int);
	Append(t:String);
	Prepend(t:String);
}

typedef IntOrString = OneOfTwo<Int, String>;

class GJClient {
	/**
	 * If set to `true`, requests will be made using `Md5` signature encryptation. \
	 * If set to `false`, they'll use `Sha1` signature encryptation instead.
	 * 
	 * Default is `true`.
	 */
	public var useMd5:Bool = true;

	/**
	 * A holder that keeps loaded information of the user that's currently logged in. \
	 * If there's no session active, this will be `null`.
	 */
	public var session(default, null):Null<Session> = null;

	/**
	 * A holder that keeps loaded information about the Data Store of your game.
	 * If there's no session active, this will be `null`.
	 */
	public var gameStore(default, null):Null<Map<String, IntOrString>> = null;

	// Holders :)
	var game:{id:Int, key:String};
	var user:{name:String, token:String} = {name: '', token: ''};

	// The ping state, updated by the game window focus
	var pingState:String = 'active';

	/**
	 * Creates a new `GJClient` constructor.
	 * @param game The ID and Private Key of your game goes here.
	 * @param pingInterval Interval in seconds for the Client to make ping session signals to GameJolt. Default is 3.
	 */
	public function new(game:{id:Int, key:String}, pingInterval:Float = 3) {
		this.game = game;
		Application.current.window.onFocusIn.add(() -> pingState = 'active');
		Application.current.window.onFocusOut.add(() -> pingState = 'idle');

		if (pingInterval < 1)
			pingInterval = 1;
		if (pingInterval > 60)
			pingInterval = 60;

		new Timer(pingInterval * 1000).run = () -> Thread.create(pingSession);
		trace('GJClient Initialized! | Ping Interval: ${pingInterval}s');
	}

	/**
	 * Opens a new session and writes `session` and `gameStore` variables if successful.
	 * @param newUser The username and user token of the new user to log in.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function login(newUser:Null<{name:String, token:String}>):Future<User> {
		user = newUser;
		var promise = new Promise<User>();

		Thread.create(function() {
			if (session != null) {
				promise.error("You're already logged in!");
				return;
			}

			var auth = request("users", "auth");
			promise.progress(1, 3);
			if (auth.message == null) {
				var connect = request("sessions", "open");
				promise.progress(2, 3);
				if (connect.message == null) {
					var u = getUserData();
					var t = getTrophiesList();
					var f = getFriendsList();
					var d = dataFetch();
					promise.progress(3, 3);

					if (u != null && t != null && f != null && d != null) {
						session = {
							info: u[0],
							trophies: t,
							friends: f,
							data: d
						};
						promise.complete(u[0]);
					} else {
						logout();
						promise.error("Failed to fetch session data");
						return;
					}
				} else {
					promise.error(connect.message);
					return;
				}
			} else {
				promise.error(auth.message);
				return;
			}
		});

		return promise.future;
	}

	/**
	 * Close the current session and makes `null` the `session` and `gameStore` variables.
	 */
	public function logout() {
		request("sessions", "close");
		user = {name: "", token: ""};
		session = null;
		gameStore = null;
	}

	/**
	 * Makes the user to achieve a trophy.
	 * Calls `getTrophiesList()` afterwards to update `session` variable data.
	 * @param id The ID of the trophy to achieve.
	 * @param remove Whether to remove the trophy after achieving it or not. Useful for test out trophies and such.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function addTrophie(id:Int, remove:Bool = false):Future<Trophy> {
		var promise = new Promise<Trophy>();

		Thread.create(function() {
			var data = request('trophies', 'add-achieved', ['trophy_id' => Std.string(id)]);
			promise.progress(1, 3);
			if (data.message == null) {
				var data2 = request('trophies', 'remove-achieved', ['trophy_id' => Std.string(id)]);
				if (data2.message != null)
					trace('Could not remove the trophie after test');

				var list = getTrophiesList();
				promise.progress(2, 3);
				if (list != null)
					for (trophy in list)
						if (trophy.id == id) {
							promise.progress(3, 3);
							promise.complete(trophy);
							break;
						}
			} else
				promise.error(data.message);
		});

		return promise.future;
	}

	/**
	 * Fetches information about one of more users, you can set them by their username or ID. \
	 * It also updates the `info` field of the `session` variable if this succeed (this just in case you leave `ids` parameter null or empty).
	 * @param ids The list of usernames and/or IDs of the user to fetch information from.
	 * 				If you left this `null` or empty, this will return information about the user that's currently logged in.
	 * 				NOTE: If you pass an ID, there must be ONLY IDs in the list, and if you pass a username,
	 * 				there must be ONLY usernames in the list. Otherwise, this wouldn't work correctly.
	 * @return The list of the users and their information if succeded.
	 */
	public function getUserData(?ids:Array<IntOrString>):Null<Array<User>> {
		var idList:Array<String> = [];
		if (ids != null)
			for (id in ids)
				idList.push(Std.string(id));

		var nullIDs:Bool = ids == null || ids == [];
		var data = request('users', null, !nullIDs ? [(ids[0] is Int ? 'user_id' : 'username') => idList.join(",")] : null, nullIDs, false);
		if (data.message == null) {
			for (daUser in data.users) {
				var newPFP = daUser.avatar_url.substring(0, 32);
				newPFP += '1000';
				newPFP += daUser.avatar_url.substr(34);
				daUser.avatar_url = newPFP;
			}

			if (session != null && nullIDs)
				session.info = data.users[0];
			return data.users;
		}

		trace(data.message);
		return null;
	}

	/**
	 * Fetches and updates the friends list of the user that's currently logged in. \
	 * It also updates the `friends` field of the `session` variable if this succeed.
	 * @return The list of the user's friends and their information if succeded.
	 */
	public function getFriendsList():Null<Array<User>> {
		var data = request('friends');

		if (data.message == null) {
			var ids:Array<Int> = [];
			for (daFriend in data.friends)
				ids.push(daFriend.friend_id);

			var list = getUserData(ids);
			if (session != null && list != null)
				session.friends = list;
			return list;
		}

		trace(data.message);
		return null;
	}

	/**
	 * Fetches and updates the states of the trophies list from your game of the user that's currently logged in. \
	 * It also updates the `trophies` field of the `session` variable if this succeed.
	 * @return The list of the updated trophies states and their information if succeded.
	 */
	public function getTrophiesList():Null<Array<Trophy>> {
		var data = request('trophies');

		if (data.message == null) {
			for (t in data.trophies) {
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
							newUrl += "9c2c91d0";
						case "trophy-silver-1":
							newUrl += "b46e352e";
						case "trophy-gold-1":
							newUrl += "363ce2dc";
						case "trophy-platinum-1":
							newUrl += "92e5330d";
						default:
					}
					newUrl += ".png";
				}
				t.image_url = newUrl;
			}
			if (session != null)
				session.trophies = data.trophies;
			return data.trophies;
		}

		trace(data.message);
		return null;
	}

	/**
	 * Fetches information from the Data Store of the User or the Game.
	 * It also updates the `session` or `gameStore` variable if this succeed.
	 * @param fromUser Retrieve from user [`true`] or for the game [`false`]?
	 * @return The mapped data
	 */
	public function dataFetch(fromUser:Bool = true):Null<Map<String, IntOrString>> {
		var data = request('data-store', 'get-keys', null, fromUser, fromUser);
		var store:Map<String, IntOrString> = [];

		if (data.message == null) {
			for (key in data.keys) {
				var value = dataGet(key.key, fromUser);
				if (value != null)
					store.set(key.key, value);
			}

			if (session != null)
				if (fromUser)
					session.data = store;
				else
					gameStore = store;

			return store;
		}

		trace(data.message);
		return null;
	}

	/**
	 * Sets a value for a key or creates a new key with the value in Data Store
	 * @param key The key name
	 * @param value The value for the key
	 * @param forUser Set for user [`true`] or for the game [`false`] ?
	 */
	public function dataSet(key:String, value:IntOrString, forUser:Bool = true) {
		var data = request('data-store', 'set', ['key' => key, 'data' => Std.string(value)], forUser, forUser);
		if (data.message != null)
			trace(data.message);
		else
			dataFetch(forUser);
	}

	public function dataGet(key:String, fromUser:Bool = true):Null<IntOrString> {
		var data = request('data-store', null, ['key' => key], fromUser, fromUser);
		if (data.message != null) {
			trace(data.message);
			return null;
		}

		var number = Std.parseFloat(data.data);
		if (!Math.isNaN(number)) {
			var newNumber = Math.round(number);
			dataSet(key, newNumber, fromUser);
			return newNumber;
		}

		return data.data;
	}

	public function dataRemove(key:String, fromUser:Bool = true) {
		var data = request('data-store', 'remove', ['key' => key], fromUser, fromUser);
		if (data.message != null)
			trace(data.message);
		else
			dataFetch(fromUser);
	}

	public function dataUpdate(key:String, action:DataUpdateType, forUser:Bool = true) {
		var value = dataGet(key);
		if (value == null)
			return;

		var params:Map<String, String> = ['key' => key];
		switch (action) {
			case Add(n):
				params.set('operation', 'add');
				params.set('value', Std.string(n));
			case Substract(n):
				params.set('operation', 'substract');
				params.set('value', Std.string(n));
			case Multiply(n):
				params.set('operation', 'multiply');
				params.set('value', Std.string(n));
			case Divide(n):
				params.set('operation', 'divide');
				params.set('value', Std.string(n));
			case Append(t):
				params.set('operation', 'append');
				params.set('value', t);
			case Prepend(t):
				params.set('operation', 'prepend');
				params.set('value', t);
		}

		var data = request('data-store', 'update', params, forUser, forUser);
		if (data.message != null)
			trace(data.message);
		else
			dataFetch(forUser);
	}

	function pingSession() {
		if (session == null)
			return;

		var ping = request("sessions", "ping");
		if (ping.message != null) {
			logout();
			trace(ping.message);
		}
	}

	function request(command:String, ?action:String, ?params:Map<String, String>, userAllowed:Bool = true, tokenAllowed:Bool = true):Response {
		var mainURL:String = "http://api.gamejolt.com/api/game/v1_2/";
		var process:String = '$command${action != null ? '/$action' : ""}';

		mainURL += process;
		mainURL += '/?game_id=${game.id}';

		if (userAllowed)
			mainURL += '&username=${user.name}';
		if (tokenAllowed)
			mainURL += '&user_token=${user.token}';
		if (params != null)
			for (k => v in params)
				mainURL += '&$k=$v';

		var daEncode:String = mainURL + game.key;
		mainURL += '&signature=${useMd5 ? Md5.encode(daEncode) : Sha1.encode(daEncode)}';

		var response:Response;
		var data = new Http(mainURL);
		data.onData = function(req) {
			response = cast Json.parse(req.toString()).response;
			if (response.message != null)
				response.message = '"$process" => ${response.message}';
		};
		data.onError = e -> response = {success: "false", message: '"$process" => $e'};
		data.request(false);
		return response;
	}
}
