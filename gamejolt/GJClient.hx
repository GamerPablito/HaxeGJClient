package gamejolt;

import haxe.Json;
import haxe.Timer;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import lime.app.Event;
import lime.utils.Bytes;
import sys.thread.Thread;

using StringTools;

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
 * The way the current session info is formatted like in here.
 * @param userInfo The general info of the User
 * @param friends The friend list of the User, along with each one's general info
 * @param trophies The list of trophies (locked and unlocked) in the game the User counts with
 */
typedef Session = {
	userInfo:User,
	friends:Array<User>,
	trophies:Array<Trophy>
}

/**
 * A completely original GameJolt Client made by [GamerPablito](https://https://twitter.com/GamerPablito1)
 * using some tools from Haxe and Lime to gather info from the GameJolt API with ease.
 * 
 * No extra extensions required at all!
 * 
 * Originally made for the game Friday Night Funkin', but it can also be used for every game made with HaxeFlixel.
 * 
 * ## Example of Use for Event Hosts:
 * Parameters for these are the following:
 * - The new function to add to this event along the vessel variable for returning if variable is not of type Void, otherwise leave it as `()`.
 * - Whether you want this to be executed once or not. `False` by default.
 * - The priority of the function (if you set many), the more its value, the sooner will be executed. Default is 0.
 */
class GJClient {
	/**
	 * Event host where you can manage actions when a `Trophy` is achieved. \
	 * Useful when it comes to trigger them with the `Trophy` data for popup notifications or related stuff.
	 * 
	 * ```haxe
	 * // Example line:
	 * onTrophy.add(function (trophy) {trace(trophy);}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onTrophy:Event<Trophy->Void> = new Event<Trophy->Void>();

	/**
	 * Event host where you can manage actions when the `User` connects with GameJolt. \
	 * Useful when it comes to trigger them with the `User` data for popup notifications or related stuff.
	 * 
	 * ```haxe
	 * // Example line:
	 * onConnect.add(function (user) {trace(user);}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onConnect:Event<User->Void> = new Event<User->Void>();

	/**
	 * Event host where you can manage actions when the `User` disconnects from GameJolt. \
	 * You can set up this to make actions in case this occur.
	 * 
	 * ```haxe
	 * // Example line:
	 * onDisconnect.add(function () {trace("callback");}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onDisconnect:Event<Void->Void> = new Event<Void->Void>();

	/**
	 * Event host where you can manage actions when the `refresh()` action has started. \
	 * An use of this can be like, if you want to show loading sprites or make something to happen before data is refreshed.
	 * 
	 * ```haxe
	 * // Example line:
	 * onRefreshStart.add(function () {trace("callback");}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onRefreshStart:Event<Void->Void> = new Event<Void->Void>();

	/**
	 * Event host where you can manage actions when the `refresh()` action ended with success. \
	 * Can be used to give a visual advertisement about the data refreshment failure.
	 * 
	 * ```haxe
	 * // Example line:
	 * onRefreshError.add(function () {trace("callback");}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onRefreshError:Event<Void->Void> = new Event<Void->Void>();

	/**
	 * Event host where you can manage actions when the `refresh()` actions ends with success. \
	 * You can set actions here to make things to happen using the updated data.
	 * 
	 * ```haxe
	 * // Example line:
	 * onRefreshEnd.add(function () {trace("callback");}, false, 0);
	 * ```
	 * 
	 * @see Instructions of Use for Events in the Client Description
	 */
	public var onRefreshEnd:Event<Void->Void> = new Event<Void->Void>();

	/**
	 * If valid, the name and the token of the input `User` will be registered here. \
	 * These data are indispensable in actions processing.
	 */
	public var user:Null<{name:String, token:String}> = null;

	/**
	 * If a session is open, all info about the current `User` will be registered here (General Info, Trophies and Friends). \
	 * If the user is logged out, this will always return `null`.
	 */
	public var session(default, null):Null<Session> = null;

	/**
	 * The time in seconds of the delay for session pinging signals.
	 * Must be a value between 1-60. Default is 3.
	 */
	public var pingDelay(default, set):Float = 3;

	/**
	 * If `true`, processings will be signed with `Md5` encoding system. \
	 * If `false`, processings will be signed with `Sha1` encoding system instead. \
	 * Default is `true`.
	 */
	public var useMd5:Bool = true;

	/**
	 * If you want to know details about the processings and stuff through the console, enable this.
	 */
	public var showAllProcessings:Bool = false;

	/**
	 * If you want to know the errors during processings through the console, enable this.
	 */
	public var showAllAlerts:Bool = false;

	var game:{id:Int, key:String};
	var pingTimer:Timer;

	/**
	 * Creates a new `GJClient` global instance.
	 * 
	 * @param game The ID and the Private Key of your game goes here
	 * @param user The name and the token of a user for auto-login goes here (optional)
	 */
	public function new(game:{id:Int, key:String}, ?user:{name:String, token:String}) {
		this.game = game;
		if (user != null)
			this.user = user;

		login();
		refreshPingTimer(pingDelay);
		if (showAllProcessings)
			trace('GameJolt Client Initialized!');
	}

	/**
	 * Connects the User (with the `user` variable data) to GameJolt. \
	 * This also set up `session` variable data and dispatches actions set in the `onConnect` Event Host if ends with success.
	 */
	public function login() {
		if (session == null) {
			var auth = urlConstruct('users', 'auth');
			if (auth != null) {
				urlConstruct('sessions', 'open');
				refresh();
				if (session != null)
					onConnect.dispatch(session.userInfo);
			} else {
				if (showAllAlerts)
					trace('Failed to authenticate incoming user data');

				user = null;
			}
		}
	}

	/**
	 * Disconnects the User from GameJolt. \
	 * This also makes `session` variable to be `null` and dispatches actions set in the `onDisconnect` Event Host if ends with success.
	 * 
	 * @param quitUser Whether the `user` variable will be set to `null` along or not
	 */
	public function logout(quitUser:Bool = false) {
		if (session != null) {
			urlConstruct('sessions', 'close');
			session = null;
			onDisconnect.dispatch();

			if (quitUser)
				user = null;
		}
	}

	/**
	 * If there's a session active, this will refresh and update `session` variable. \
	 * This also dispatches its 3 Event Hosts depending of the process state:
	 * - `onRefreshStart`: When the process start
	 * - `onRefreshError`: When the process ends with error
	 * - `onRefreshEnd`: When the process ends with success
	 */
	public function refresh() {
		if (session != null) {
			onRefreshStart.dispatch();

			var userInfo = getUserData();
			var trophies = getTrophiesList();
			var friends = getFriendsList();

			if (userInfo != null && trophies != null && friends != null) {
				if (showAllProcessings)
					trace('Current user data was successfully refreshed');

				session = {userInfo: userInfo, trophies: trophies, friends: friends};
				onRefreshEnd.dispatch();
			} else {
				if (showAllAlerts)
					trace('Current user data failed to refresh, logging out...');

				logout(true);
				onRefreshError.dispatch();
			}
		}
	}

	/**
	 * If there's a session active, this makes the user achieve a trophy of your game. \
	 * This also dispatches actions set in the `onTrophy` Event Host along with this trophy data if ends with success.
	 * @param id A valid ID of the trophy to achieve
	 */
	public function addTrophie(id:Int) {
		if (session != null) {
			Thread.create(function() {
				if (showAllProcessings)
					trace('Adding Trophy with ID: $id ...');

				var process = urlConstruct('trophies', 'add-achieved', ['trophy_id' => Std.string(id)]);
				if (process != null) {
					for (t in session.trophies)
						if (t.id == id) {
							var updatedTrophies = getTrophiesList();
							if (updatedTrophies != null)
								session.trophies = updatedTrophies;

							onTrophy.dispatch(t);
							if (showAllProcessings)
								trace('Trophy with ID ($id) was successfully registered as achieved');
							break;
						}
				} else if (showAllAlerts)
					trace('Failed to register trophy with ID ($id) as achieved');
			});
		}
	}

	function getTrophiesList():Null<Array<Trophy>> {
		var trophList:Null<Array<Trophy>> = null;
		var data = urlConstruct('trophies');

		if (data != null) {
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
			}
		};
		return trophList;
	}

	function getFriendsList():Null<Array<User>> {
		var friends:Null<Array<User>> = null;
		var data = urlConstruct('friends');

		if (showAllProcessings)
			trace('Loading friend list from current user');

		if (data != null) {
			var list:Array<Dynamic> = data.friends;
			friends = [];

			for (person in list) {
				var fetchPerson = getUserData(Std.int(person.friend_id));
				if (fetchPerson != null)
					friends.push(fetchPerson);
			}

			if (showAllProcessings)
				trace('Friend list loaded!');
		} else if (showAllAlerts)
			trace('Failed to load friend list from the current user');

		return friends;
	}

	function getUserData(?id:Int):Null<User> {
		var result:Null<User> = null;
		var data = urlConstruct('users', null, id != null ? ['user_id' => Std.string(id)] : null, id == null, false);

		if (showAllProcessings)
			trace('Loading user with ${id == null ? "the input ID" : 'ID: $id'} ...');

		if (data != null) {
			var daUser:User = cast data.users[0];
			var newUrl:String = daUser.avatar_url.substring(0, 32);

			newUrl += '1000';
			newUrl += daUser.avatar_url.substr(34);
			newUrl = newUrl.replace(".jpg", ".png");
			daUser.avatar_url = newUrl;
			result = daUser;

			if (showAllProcessings)
				trace('Loaded info from user: "${daUser.developer_name}"');
		} else if (showAllAlerts)
			trace('Failed to load user with ID: ${id == null ? "the input ID" : ' $id'}');

		return result;
	}

	function ping() {
		Thread.create(function() {
			if (session != null) {
				var process = urlConstruct('sessions', 'ping');
				if (process == null) {
					if (showAllAlerts)
						trace('Logging out due to ping fail');

					logout();
				}
			}
		});
	}

	function refreshPingTimer(value:Float) {
		if (pingTimer != null)
			pingTimer.stop();

		pingTimer = new Timer(value * 1000);
		pingTimer.run = ping;

		if (showAllProcessings)
			trace('Pinging interval is active with a delay of $value seconds');
	}

	function set_pingDelay(value:Float) {
		if (value < 1)
			value = 1;
		if (value > 60)
			value = 60;
		refreshPingTimer(value);
		return pingDelay = value;
	}

	function urlConstruct(command:String, ?action:String, ?params:Map<String, String>, userAllowed:Bool = true, tokenAllowed:Bool = true):Null<Dynamic> {
		var mainURL:String = "http://api.gamejolt.com/api/game/v1_2/";
		var process:String = '$command${action != null ? '/$action' : ""}';
		var result:Null<Dynamic> = null;
		mainURL += process;
		mainURL += '/?game_id=${game.id}';

		if (showAllProcessings)
			trace('Processing: "$mainURL" ...');

		if ((userAllowed || tokenAllowed) && user == null) {
			if (showAllAlerts)
				trace('User info is required to make "$process" request to work');
		} else {
			if (userAllowed)
				mainURL += '&username=${user.name}';
			if (tokenAllowed)
				mainURL += '&user_token=${user.token}';
			if (params != null)
				for (k => v in params)
					mainURL += '&$k=$v';

			var daEncode:String = mainURL + game.key;
			mainURL += '&signature=${useMd5 ? Md5.encode(daEncode) : Sha1.encode(daEncode)}';

			var data = Bytes.fromFile(mainURL);
			if (data != null) {
				result = cast Json.parse(data.toString()).response;
				if (result.message != null) {
					if (showAllAlerts)
						trace('Failed to process "$process" request -> ${result.message}');

					result = null;
				}
			}
		}

		return result;
	}
}
