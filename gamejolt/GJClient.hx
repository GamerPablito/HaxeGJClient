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
}

/**
 * When there's a session active, data is loaded using this formatted here,
 * so you don't have to make repetitive requests just to get the same data all the time.
 * 
 * @param info Information data about the current user logged in.
 * @param friends Friends List from the current user logged in.
 * @param trophies Trophies LIst and their state according to the data from the current user logged in.
 */
typedef Session = {
	info:User,
	friends:Array<User>,
	trophies:Array<Trophy>
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

	var game:{id:Int, key:String};
	var user:{name:String, token:String} = {name: '', token: ''};
	var pingState:String = 'active';

	/**
	 * Makes a new `GJClient` constructor.
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
	 * Opens a new session and writes `session` variable if successful.
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
					promise.progress(3, 3);

					if (u != null && t != null && f != null) {
						session = {info: u[0], trophies: t, friends: f};
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
	 * Close the current session and makes `null` the `session` variable.
	 */
	public function logout() {
		request("sessions", "close");
		user = {name: "", token: ""};
		session = null;
	}

	/**
	 * Makes the user to achieve a trophy.
	 * Calls `getTrophiesList()` afterwards to update `session` variable data.
	 * @param id The ID of the trophy to achieve.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function trophieAdd(id:Int):Future<Trophy> {
		var promise = new Promise<Trophy>();

		Thread.create(function() {
			var data = request('trophies', 'add-achieved', ['trophy_id' => Std.string(id)]);
			promise.progress(1, 3);
			if (data.message == null) {
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
	 * Removes an achieved trophy from the user, useful when you're about to test your game trophies. \
	 * Calls `getTrophiesList()` afterwards to update `session` variable data.
	 * @param id The ID of the trophy to remove.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function trophieRemove(id:Int):Future<Trophy> {
		var promise = new Promise<Trophy>();

		Thread.create(function() {
			var data = request('trophies', 'remove-achieved', ['trophy_id' => Std.string(id)]);
			promise.progress(1, 3);
			if (data.message == null) {
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
	public function getUserData(?ids:Array<OneOfTwo<Int, String>>):Null<Array<User>> {
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
		var promise = new Promise<Response>();
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
