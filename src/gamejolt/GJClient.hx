package gamejolt;

import gamejolt.formats.*;
import gamejolt.types.DataUpdateType;
import haxe.Timer;
import lime.app.Application;
import lime.app.Future;
import lime.app.Promise;
import sys.thread.Thread;

using Lambda;
using StringTools;

/**
 * An special class made by [GamerPablito](https://twitter.com/GamerPablito1) to communicate with GameJolt API with a relative ease. \
 * This contains many tools and functions using many `GJRequest` calls. Including constant session pinging. \
 * Don't forget to set data for the `game` variable before creating a new instance!
 * @see The [Wiki Page](https://github.com/GamerPablito/HaxeGJClient/wiki) for more info about its use.
 */
class GJClient {
	/**
	 * Put you game website API credentials in here, they'll be used by `GJRequest` for command creations and calls.
	 */
	public static var game:{id:Int, key:String} = {id: 0, key: ""};

	/**
	 * If you got user credentials you can set them here for actions that requires them. \
	 * If you set `user` but don't set `token`, you'll be joined as guest (But you won't be able to submit anything but Scores). \
	 * Leave in blank if there are no user credentials to pass in yet.
	 */
	public static var account:Account = {user: "", token: ""};

	/**
	 * If there's a session currently active, the user info will be displayed here.
	 */
	public var loginInfo(default, null):Null<User> = null;

	var pingReq:GJRequest;
	var timeReq:GJRequest;
	var loginReq:GJRequest;
	var logoutReq:GJRequest;
	var trophieAdd:GJRequest;
	var scoreAdd:GJRequest;
	var friends:GJRequest;
	var dataUser:GJRequest;
	var dataGame:GJRequest;
	var dataByMap:GJRequest;

	var pingActive(default, set):Bool;

	/**
	 * Creates a new `GJClient` instance. \
	 * Better to place it in a class where it's going to be executed globally.
	 * 
	 * @param pingInterval The delay (in seconds) of session ping signals.
	 * 						Must be a value between 0-120, otherwise it won't work as expected.
	 * 						Default is 5.
	 */
	public function new(pingInterval:Float = 5) {
		pingReq = new GJRequest();
		pingReq.onError = function(e) {
			if (loginInfo != null) {
				trace("Ping failed, You were logged out!");
				logout();
			}
		}

		timeReq = new GJRequest().urlFromType(TIME);
		loginReq = logoutReq = trophieAdd = scoreAdd = dataUser = dataGame = dataByMap = friends = new GJRequest();

		pingActive = true;
		Application.current.window.onFocusIn.add(() -> pingActive = true);
		Application.current.window.onFocusOut.add(() -> pingActive = false);
		Application.current.onExit.add(exitCode -> logout());

		new Timer(pingInterval * 1000).run = () -> ping();
	}

	function ping()
		if (!loginReq.isProcessing && !logoutReq.isProcessing)
			pingReq.executeAsync();

	/**
	 * Receives the content from the Data Store with a certain key. Runs Syncronously. \
	 * NOTE: It won't execute if another Data Store function is still in progress to finish.
	 * @param key The key of the value you want to be fetch.
	 * @param forUser Whether to fetch this from the User Data Store or the Game Data Store.
	 * @return The value of the key, but if the request was failed, an empty string.
	 */
	public function dataGet(key:String, fromUser:Bool):String {
		if (dataUser.isProcessing || dataGame.isProcessing || dataByMap.isProcessing) {
			trace("Some Data Store function has not finished yet for dataGet() to work!");
			return "";
		}
		var value = "";
		var keyGet = new GJRequest().urlFromType(DATA_FETCH(key, fromUser));
		keyGet.onSuccess = res -> value = res.data;
		keyGet.onError = e -> trace(e);
		keyGet.execute();
		return value;
	}

	/**
	 * Sets a value for a certain key in the Data Store. Runs Syncronously. \
	 * NOTE: It won't execute if another Data Store function is still in progress to finish.
	 * @param key The key whose value is gonna be assignated/overwritten to.
	 * @param value The value to set for such key.
	 * @param forUser Whether to set this to the User Data Store or the Game Data Store.
	 */
	public function dataSet(key:String, value:String, forUser:Bool) {
		if (dataUser.isProcessing || dataGame.isProcessing || dataByMap.isProcessing) {
			trace("Some Data Store function has not finished yet for dataSet() to work!");
			return;
		}
		var keySet = new GJRequest().urlFromType(DATA_SET(key, value, forUser));
		keySet.onError = e -> trace(e);
		keySet.execute();
	}

	/**
	 * Updates the content from the Data Store with a certain key. Runs Syncronously. \
	 * NOTE: It won't execute if another Data Store function is still in progress to finish.
	 * @param key The key whose value is gonna be updated.
	 * @param updateType How such value is gonna be updated like.
	 * @param forUser Whether to update this for the User Data Store or the Game Data Store.
	 */
	public function dataUpdate(key:String, updateType:DataUpdateType, forUser:Bool) {
		if (dataUser.isProcessing || dataGame.isProcessing || dataByMap.isProcessing) {
			trace("Some Data Store function has not finished yet for dataUpdate() to work!");
			return;
		}
		var keyUpdate = new GJRequest().urlFromType(DATA_UPDATE(key, updateType, forUser));
		keyUpdate.onError = e -> trace(e);
		keyUpdate.execute();
	}

	/**
	 * Removes a key (along with its content) away from the Data Store. Runs Syncronously. \
	 * NOTE: It won't execute if another Data Store function is still in progress to finish.
	 * @param key The key to remove.
	 * @param forUser Whether to remove the key from the User Data Store or the Game Data Store.
	 */
	public function dataRemove(key:String, forUser:Bool) {
		if (dataUser.isProcessing || dataGame.isProcessing || dataByMap.isProcessing) {
			trace("Some Data Store function has not finished yet for dataRemove() to work!");
			return;
		}
		var keyRemove = new GJRequest().urlFromType(DATA_REMOVE(key, forUser));
		keyRemove.onError = e -> trace(e);
		keyRemove.execute();
	}

	/**
	 * Makes the Data Store to be equal to a String Map. Runs Asyncronously. \
	 * NOTE: It won't execute if another Data Store function is still in progress to finish.
	 * @param map The String Map representing the new Data Store to be set.
	 * @param forUser Whether to set the User Data Store or the Game Data Store to this map.
	 * @param onComplete Optional callback when the process finish.
	 */
	public function dataByStringMap(map:Map<String, String>, forUser:Bool, ?onComplete:() -> Void) {
		if (dataUser.isProcessing || dataGame.isProcessing) {
			trace("Function getDataStore() has not finished to be executed!");
			return;
		}

		dataByMap.urlFromType(DATA_GETKEYS(forUser));
		dataByMap.onSuccess = function(res) {
			for (key in map.keys())
				dataSet(key, map.get(key), forUser);
			res.keys.iter(data -> if (!map.exists(data.key)) dataRemove(data.key, forUser));

			if (onComplete != null)
				onComplete();
		};
		dataByMap.onError = e -> trace(e);
		dataByMap.executeAsync();
	}

	/**
	 * Fetches a Data Store content represented as a String Map.
	 * @param fromUser Whether if you want the User Data Store or the Game Data Store to be fetched.
	 * @return A `Future` instance fetching the requested Data Store.
	 */
	public function getDataStore(fromUser:Bool):Future<Map<String, String>> {
		var promise = new Promise<Map<String, String>>();
		if (dataByMap.isProcessing)
			promise.error("Function dataByStringMap() has not finished to be executed!");
		else {
			if (fromUser) {
				dataUser.urlFromType(DATA_GETKEYS(true));
				dataUser.onSuccess = function(res) {
					var store:Map<String, String> = [];
					res.keys.iter(function(data) {
						var keyReq = new GJRequest().urlFromType(DATA_FETCH(data.key, true));
						keyReq.onSuccess = res2 -> store.set(data.key, res2.data);
						keyReq.onError = e -> trace(e);
						keyReq.execute();
					});
					promise.complete(store);
				}
				dataUser.onError = e -> promise.error(e);
				dataUser.executeAsync();
			} else {
				dataGame.urlFromType(DATA_GETKEYS(false));
				dataGame.onSuccess = function(res) {
					var store:Map<String, String> = [];
					for (data in res.keys) {
						var keyReq = new GJRequest().urlFromType(DATA_FETCH(data.key, false));
						keyReq.onSuccess = res2 -> store.set(data.key, res2.data);
						keyReq.onError = e -> trace(e);
						keyReq.execute();
					}
					promise.complete(store);
				}
				dataGame.onError = e -> promise.error(e);
				dataGame.executeAsync();
			}
		}
		return promise.future;
	}

	/**
	 * If there's a user logged in, this will return the user's friends list with their respective information.
	 * @return A `Future` instance fetching the detailed friends list.
	 */
	public function getFriendsList():Future<Array<User>> {
		var promise = new Promise<Array<User>>();
		friends.urlFromType(FRIENDS);
		friends.onSuccess = function(res) {
			var daFriends = new GJRequest().urlFromType(USER_FETCH(res.friends.map(f -> Std.string(f.friend_id))));
			daFriends.onSuccess = res2 -> promise.complete(res2.users);
			daFriends.onError = e -> promise.error(e);
			daFriends.execute();
		};
		friends.onError = e -> promise.error(e);
		friends.executeAsync();
		return promise.future;
	}

	/**
	 * Returns the current time data of the GameJolt Server, formatted in a special way.
	 * @return A `Future` instance fetching the respective data.
	 */
	public function getServerTime():Future<String> {
		var promise = new Promise<String>();
		timeReq.onSuccess = res -> promise.complete('${res.timezone} | ${res.day}/${res.month}/${res.year} | ${res.hour}:${res.minute}:${res.second}');
		timeReq.onError = e -> promise.error(e);
		timeReq.executeAsync();
		return promise.future;
	}

	/**
	 * Adds a new Score to a certain Score Table in your game, and returns the final Score data. \
	 * You can also set callbacks for whatever you need using `onSuccess` and/or `onError`.
	 * @param sort The score value (By example: 500)
	 * @param tag The tag for this score (By example: "Points", being represented in your Score Table like: 500 Points)
	 * @param extra_data Optional slot to set extra data about how the user achieved this score,
	 * 						useful when it comes to know if someone cheated.
	 * @param table_id The Score Table ID this Score will be added, if you leave it `null`,
	 * 						the Score will be added to the Primary Score Table in your game.
	 * @return A `Future` instance processing the Score registration.
	 * 			NOTE: It'll end up `onSuccess` only if the score could enter in the top 100 scores in the Score Table.
	 */
	public function addScore(sort:Int, tag:String, ?extra_data:String, ?table_id:Int):Future<Score> {
		var promise = new Promise<Score>();
		scoreAdd.urlFromBatch([
			SCORES_ADD('$sort $tag', sort, extra_data, table_id),
			SCORES_FETCH(table_id, 100),
		]);

		scoreAdd.onSuccess = function(res) {
			var daScore = res.responses[1].scores.find(s -> s.sort == sort);
			if (daScore != null)
				promise.complete(daScore);
			else
				promise.error("Not classified for the top 100 :(");
		};
		scoreAdd.onError = e -> promise.error(e);
		scoreAdd.executeAsync();
		return promise.future;
	}

	/**
	 * Makes the user achieve a Trophy from your game, and returns the final Trophy data. \
	 * You can also set callbacks for whatever you need using `onSuccess` and/or `onError`.
	 * @param id The Trophy ID the user is gonna achieve
	 * @param removeAfter Whether if you want the trophy to be removed instantly after achieving it or not.
	 * 						Useful when it comes to test Trophies out.
	 * @return A `Future` instance processing the Trophy achievement.
	 */
	public function addTrophie(id:Int, removeAfter:Bool):Future<Trophy> {
		var promise = new Promise<Trophy>();
		Thread.create(function() {
			trophieAdd.urlFromBatch([TROPHIES_ADD(id), TROPHIES_FETCH(null, id)]);
			trophieAdd.onSuccess = res -> promise.complete(res.responses[1].trophies[0]);
			trophieAdd.onError = e -> promise.error(e);
			trophieAdd.execute();
			if (removeAfter)
				new GJRequest().urlFromType(TROPHIES_REMOVE(id)).execute();
		});
		return promise.future;
	}

	/**
	 * Opens a new Session for `this` to track. It also sets `loginInfo` and returns it if this ends `onSuccess`.
	 * @return A `Future` instance processing the session opening.
	 */
	public function login():Future<User> {
		var promise = new Promise<User>();
		if (!logoutReq.isProcessing)
			promise.error("You're still logging out to be connected again...");
		else {
			if (loginInfo == null) {
				loginReq.urlFromBatch([SESSION_OPEN, USER_FETCH()]);
				loginReq.onSuccess = res -> promise.complete(loginInfo = res.responses[1].users[0]);
				loginReq.onError = e -> promise.error(e);
				loginReq.executeAsync();
			} else
				promise.error("User is already logged in!");
		}
		return promise.future;
	}

	/**
	 * Closes the current Session if there is one. It also sets `loginInfo` to `null`. Runs Asyncronously.
	 * @param callback Optional for when the process ends.
	 */
	public function logout(?callback:() -> Void) {
		if (loginReq.isProcessing)
			return;

		loginInfo = null;
		logoutReq.urlFromType(SESSION_CLOSE);
		logoutReq.onSuccess = res -> if (callback != null) callback();
		logoutReq.executeAsync();
	}

	function set_pingActive(value:Bool):Bool {
		pingReq.urlFromType(SESSION_PING(value));
		return pingActive = value;
	}
}
