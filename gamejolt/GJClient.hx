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
import lime.utils.Bytes;
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
	var debugNotes:Bool = false;

	/**
	 * Makes a new `GJClient` constructor.
	 * @param game The ID and Private Key of your game goes here.
	 * @param pingInterval Interval in seconds for the Client to make ping session signals to GameJolt. Default is 3.
	 */
	public function new(game:{id:Int, key:String}, pingInterval:Float = 3, debugNotes:Bool = false) {
		this.game = game;
		this.debugNotes = debugNotes;
		Application.current.window.onFocusIn.add(() -> pingState = 'active');
		Application.current.window.onFocusOut.add(() -> pingState = 'idle');

		if (pingInterval < 1)
			pingInterval = 1;
		if (pingInterval > 60)
			pingInterval = 60;

		new Timer(pingInterval * 1000).run = () -> if (request('sessions', 'ping', ['status' => pingState]).success != 'true'
			&& session != null) logout();

		if (debugNotes)
			trace('GJClient Initialized! | Ping Interval: ${pingInterval}s');
	}

	/**
	 * Opens a new session and writes `session` variable if successful.
	 * @param newUser The username and user token of the new user to log in.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function login(newUser:Null<{name:String, token:String}>):Future<User> {
		var process = new Promise<User>();

		if (newUser.name != '' && newUser.token != '') {
			if (session == null) {
				user = newUser;
				var auth = request('users', 'auth');
				if (auth.success == 'true' && !isSessionActive()) {
					var connect = request('sessions', 'open');
					if (connect.success == 'true') {
						var userInfo = getUserData();
						var friends = getFriendsList();
						var trophies = getTrophiesList();

						if (userInfo != null && friends != null && trophies != null) {
							session = {info: userInfo, friends: friends, trophies: trophies};
							process.complete(userInfo);
						} else {
							user = {name: "", token: ""};
							logout(() -> process.error("Failed to fetch session data!"));
						}
					} else {
						user = {name: "", token: ""};
						process.error(connect.message != null ? connect.message : "Something went wrong during logging in!");
					}
				} else {
					user = {name: "", token: ""};
					process.error(auth.message != null ? auth.message : "Something went wrong during authentication!");
				}
			} else
				process.error("You're already logged in!");
		} else
			process.error("User data is missing (username and/or user token)!");

		return process.future;
	}

	/**
	 * Close the current session and makes `null` the `session` variable.
	 * @param onComplete Optional action when the request is done.
	 */
	public function logout(?onComplete:() -> Void) {
		if (session != null) {
			request('sessions', 'close');
			if (!isSessionActive()) {
				user = {name: "", token: ""};
				session = null;
			}
		}
		if (onComplete != null)
			onComplete();
	}

	/**
	 * Makes the user to achieve a trophy.
	 * @param id The ID of the trophy to achieve.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function trophieAdd(id:Int):Future<Trophy> {
		var promise = new Promise<Trophy>();
		var process = request('trophies', 'add-achieved', ['trophy_id' => Std.string(id)]);
		if (process.success == 'true' && session != null) {
			var newTrophies = getTrophiesList();
			if (newTrophies != null)
				session.trophies = newTrophies;

			for (t in session.trophies)
				if (t.id == id) {
					promise.complete(t);
					break;
				}
		} else
			promise.error(process.message != null ? process.message : "Something went wrong at trophie addition!");

		return promise.future;
	}

	/**
	 * Removes an achieved trophy from the user, useful when you're about to test your game trophies.
	 * @param id The ID of the trophy to remove.
	 * @return A `Future` instance where you can set actions if this got success or failure.
	 */
	public function trophieRemove(id:Int):Future<Trophy> {
		var promise = new Promise<Trophy>();
		var process = request('trophies', 'remove-achieved', ['trophy_id' => Std.string(id)]);
		if (process.success == 'true' && session != null) {
			var newTrophies = getTrophiesList();
			if (newTrophies != null)
				session.trophies = newTrophies;

			for (t in session.trophies)
				if (t.id == id) {
					promise.complete(t);
					break;
				}
		} else
			promise.error(process.message != null ? process.message : "Something went wrong at trophie addition!");

		return promise.future;
	}

	function getUserData(?id:OneOfTwo<Int, String>):Null<User> {
		var userLoad = request('users', null, id != null ? [(id is Int ? 'user_id' : 'username') => Std.string(id)] : null, id == null, false);
		if (userLoad.success == 'true') {
			var daUser = userLoad.users[0];
			var newPFP = daUser.avatar_url.substring(0, 32);

			newPFP += '1000';
			newPFP += daUser.avatar_url.substr(34);
			daUser.avatar_url = newPFP;

			return daUser;
		}

		return null;
	}

	function getFriendsList():Null<Array<User>> {
		var data = request('friends');
		if (data.success == 'true') {
			var friends:Array<User> = [];
			for (person in data.friends) {
				var fetchPerson = getUserData(person.friend_id);
				if (fetchPerson == null)
					continue;

				friends.push(fetchPerson);
			}
			return friends;
		}

		return null;
	}

	function getTrophiesList():Null<Array<Trophy>> {
		var trophList:Null<Array<Trophy>> = null;
		var data = request('trophies');

		if (data.success == 'true') {
			trophList = data.trophies;

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
		};
		return trophList;
	}

	function isSessionActive():Bool
		return request('sessions', 'check').success == 'true';

	function request(command:String, ?action:String, ?params:Map<String, String>, userAllowed:Bool = true, tokenAllowed:Bool = true):Future<Response> {
		Thread.create(function() {
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
			data.onData = req -> response = cast Json.parse(req).response;
			data.onError = error -> response = {success: 'false', message: error};
			data.request(false);

			if (response.message != null && debugNotes)
				trace('"$process" => ${response.message}!');
		});

		return response;
	}
}
