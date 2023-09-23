package gamejolt;

import gamejolt.formats.*;
import gamejolt.types.*;
import haxe.Timer;
import lime.app.Application;
import lime.app.Future;
import lime.app.Promise;

using Lambda;
using StringTools;

/**
 * An special class made by [GamerPablito](https://twitter.com/GamerPablito1) to communicate with GameJolt API with a relative ease. \
 * This contains many tools and functions using many `GJRequest` calls. Including constant session pinging. \
 * Don't forget to set data for the `game` variable before creating a new instance!
 * @see The [Wiki Page](https://github.com/GamerPablito/HaxeGJClient/wiki) for more info about its use.
 */
class GJClient
{
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

	var pingActive(default, set):Bool;

	/**
	 * Creates a new `GJClient` instance. \
	 * Better to place it in a class where it's going to be executed globally.
	 * 
	 * @param pingInterval The delay (in seconds) of session ping signals.
	 * 						Must be a value between 0-120, otherwise it won't work as expected.
	 * 						Default is 5.
	 */
	public function new(pingInterval:Float = 5)
	{
		timeReq = new GJRequest().urlFromType(TIME);
		pingReq = new GJRequest();
		pingReq.onError = function(e)
		{
			if (loginInfo != null)
			{
				trace("Ping failed, You were logged out!");
				logout();
			}
		}

		pingActive = true;
		Application.current.window.onFocusIn.add(() -> pingActive = true);
		Application.current.window.onFocusOut.add(() -> pingActive = false);
		Application.current.onExit.add(exitCode -> logout());

		new Timer(pingInterval * 1000).run = () -> ping();
	}

	function ping()
		pingReq.executeAsync();

	/**
	 * Receives the content from the Data Store with a certain key.
	 * @param key The key of the value you want to be fetch.
	 * @param forUser Whether to fetch this from the User Data Store or the Game Data Store.
	 * @return A `Future` instance fetching the requested data from the key passed in.
	 */
	public function dataGet(key:String, fromUser:Bool):Future<String>
	{
		var promise = new Promise<String>();
		var keyGet = new GJRequest().urlFromType(DATA_FETCH(key, fromUser));
		keyGet.onSuccess = res -> promise.complete(res.data);
		keyGet.onError = e -> promise.error(e);
		keyGet.executeAsync();
		return promise.future;
	}

	/**
	 * Sets a value for a certain key in the Data Store. Runs Syncronously.
	 * @param key The key whose value is gonna be assignated/overwritten to.
	 * @param value The value to set for such key.
	 * @param forUser Whether to set this to the User Data Store or the Game Data Store.
	 */
	public function dataSet(key:String, value:String, forUser:Bool)
	{
		var keySet = new GJRequest().urlFromType(DATA_SET(key, value, forUser));
		keySet.onError = e -> trace(e);
		keySet.execute();
	}

	/**
	 * Updates the content from the Data Store with a certain key. Runs Syncronously.
	 * @param key The key whose value is gonna be updated.
	 * @param updateType How such value is gonna be updated like.
	 * @param forUser Whether to update this for the User Data Store or the Game Data Store.
	 */
	public function dataUpdate(key:String, updateType:DataUpdateType, forUser:Bool)
	{
		var keyUpdate = new GJRequest().urlFromType(DATA_UPDATE(key, updateType, forUser));
		keyUpdate.onError = e -> trace(e);
		keyUpdate.execute();
	}

	/**
	 * Removes a key (along with its content) away from the Data Store. Runs Syncronously.
	 * @param key The key to remove.
	 * @param forUser Whether to remove the key from the User Data Store or the Game Data Store.
	 */
	public function dataRemove(key:String, forUser:Bool)
	{
		var keyRemove = new GJRequest().urlFromType(DATA_REMOVE(key, forUser));
		keyRemove.onError = e -> trace(e);
		keyRemove.execute();
	}

	/**
	 * Makes the Data Store to be equal to a String Map. Runs Asyncronously.
	 * @param map The String Map representing the new Data Store to be set.
	 * @param forUser Whether to set the User Data Store or the Game Data Store to this map.
	 * @param onComplete Optional callback when the process finish.
	 */
	public function dataByStringMap(map:Map<String, String>, forUser:Bool, ?onComplete:() -> Void)
	{
		var dataByMap = new GJRequest().urlFromType(DATA_GETKEYS(forUser));
		dataByMap.onSuccess = function(res)
		{
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
	public function getDataStore(fromUser:Bool):Future<Map<String, String>>
	{
		var promise = new Promise<Map<String, String>>();
		var dataStoreGet = new GJRequest().urlFromType(DATA_GETKEYS(fromUser));
		dataStoreGet.onSuccess = function(res)
		{
			var store:Map<String, String> = [];
			res.keys.iter(function(data)
			{
				var keyReq = new GJRequest().urlFromType(DATA_FETCH(data.key, fromUser));
				keyReq.onSuccess = res2 -> store.set(data.key, res2.data);
				keyReq.onError = e -> trace(e);
				keyReq.execute();
			});
			promise.complete(store);
		}
		dataStoreGet.onError = e -> promise.error(e);
		dataStoreGet.executeAsync();
		return promise.future;
	}

	/**
	 * If there's a user logged in, this will return the user's friends list with their respective information.
	 * @return A `Future` instance fetching the detailed friends list.
	 */
	public function getFriendsList():Future<Array<User>>
	{
		var promise = new Promise<Array<User>>();
		var friends = new GJRequest().urlFromType(FRIENDS);
		friends.onSuccess = function(res)
		{
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
	public function getServerTime():Future<String>
	{
		var promise = new Promise<String>();
		timeReq.onSuccess = res -> promise.complete('${res.timezone} | ${res.day}/${res.month}/${res.year} | ${res.hour}:${res.minute}:${res.second}');
		timeReq.onError = e -> promise.error(e);
		timeReq.executeAsync();
		return promise.future;
	}

	/**
	 * Returns all the Score Tables registered in your game.
	 * @param id If you want to fetch an specific Score Table, you can set the ID here.
	 * @return A `Future` instance of the Score Tables load.
	 */
	public function getScoreTables(?id:Int):Future<Array<ScoreTable>>
	{
		var promise = new Promise<Array<ScoreTable>>();
		var scoreTable = new GJRequest().urlFromType(SCORES_TABLES);
		scoreTable.onSuccess = function(res)
		{
			if (id != null)
			{
				var daTable = res.tables.find(t -> t.id == id);
				if (daTable != null)
					promise.complete([daTable]);
				else
					promise.error('Invalid Score Table ID: $id');
			}
			else
				promise.complete(res.tables);
		};
		scoreTable.onError = e -> promise.error(e);
		scoreTable.executeAsync();
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
	public function addScore(sort:Int, tag:String, ?extra_data:String, ?table_id:Int):Future<Score>
	{
		var promise = new Promise<Score>();
		var scoreAdd = new GJRequest().urlFromBatch([
			SCORES_ADD('$sort $tag', sort, extra_data, table_id),
			SCORES_FETCH(table_id, 100),
		]);

		scoreAdd.onSuccess = function(res)
		{
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
	public function addTrophy(id:Int, removeAfter:Bool = false):Future<Trophy>
	{
		var promise = new Promise<Trophy>();
		var requests:Array<RequestType> = [TROPHIES_ADD(id), TROPHIES_FETCH(null, id)];
		if (removeAfter)
			requests.push(TROPHIES_REMOVE(id));

		var trophyAdd = new GJRequest().urlFromBatch(requests);
		trophyAdd.ignoreSubErrors = true;
		trophyAdd.onSuccess = function(res)
		{
			var removeRes = res.responses[2];
			if (removeRes != null)
				if (removeRes.message != null)
					trace(removeRes.message);

			var fetchError = res.responses[1].message;
			if (fetchError == null)
				promise.complete(res.responses[1].trophies[0]);
			else
				promise.error(fetchError);
		}
		trophyAdd.onError = e -> promise.error(e);
		trophyAdd.execute();
		return promise.future;
	}

	/**
	 * Opens a new Session for `this` to track. It also sets `loginInfo` and returns it if this ends `onSuccess`.
	 * @return A `Future` instance processing the session opening.
	 */
	public function login():Future<User>
	{
		var promise = new Promise<User>();
		if (loginInfo == null)
		{
			var loginReq = new GJRequest().urlFromBatch([SESSION_OPEN, USER_FETCH()]);
			loginReq.onSuccess = res -> promise.complete(loginInfo = res.responses[1].users[0]);
			loginReq.onError = e -> promise.error(e);
			loginReq.executeAsync();
		}
		else
			promise.error("User is already logged in!");
		return promise.future;
	}

	/**
	 * Closes the current Session if there is one. It also sets `loginInfo` to `null`. Runs Asyncronously.
	 * @param callback Optional for when the process ends.
	 */
	public function logout(?callback:() -> Void)
	{
		loginInfo = null;
		var logoutReq = new GJRequest().urlFromType(SESSION_CLOSE);
		logoutReq.onSuccess = res -> if (callback != null) callback();
		logoutReq.executeAsync();
	}

	function set_pingActive(value:Bool):Bool
	{
		pingReq.urlFromType(SESSION_PING(value));
		return pingActive = value;
	}
}
