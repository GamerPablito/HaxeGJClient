package gamejolt;

import gamejolt.formats.*;
import gamejolt.types.RequestType;
import haxe.Timer;
import lime.app.Application;
import lime.app.Future;
import lime.app.Promise;

using StringTools;

/**
 * A special class made to manage exclusively user data with ease.
 * @see The [Wiki Page](https://github.com/GamerPablito/HaxeGJClient/wiki) for more info about GameJolt Calls and such.
 */
class GJUser
{
	/**
	 * The current data according of the registered User's credentials.
	 * Use `refreshData()` to update, if it's possible.
	 */
	public var data(default, null):User = {};

	/**
	 * The Data Store of the User, it can be `null` if there are no credentials registered in or if the User registered is a Guest.
	 */
	public var store(default, null):Null<GJDataStore> = null;

	/**
	 * Whether if the User is currently connected to GameJolt or not. \
	 * NOTE: It will remain `false` if the User is a Guest.
	 */
	public var logged(default, null):Bool = false;

	var pingActive:Bool = true;
	var pingTrigger:Timer;
	var token:String = "";

	/**
	 * Creates a new `GJUser` instance.
	 */
	public function new()
	{
		Application.current.window.onFocusIn.add(() -> pingActive = true);
		Application.current.window.onFocusOut.add(() -> pingActive = false);

		pingTrigger = new Timer(5000);
		pingTrigger.run = () -> if (logged)
		{
			var req = new GJRequest().urlFromType(SESSION_PING(data.username, token, pingActive));
			req.onError(function(e)
			{
				trace('Ping Error: $e. Logging out...');
				logout();
			});
			req.execute(true);
		};
	}

	/**
	 * Declares new credentials for this `GJUser` instance to use. \
	 * The `data` variable will turn to empty parameters if you leave the `user` field in blank. \
	 * NOTE: This won't work if the previously User registered here is still logged into GameJolt.
	 * @param user The username of the user.
	 * @param token The game token of the user. Leave blank if you want to be registered as guest.
	 */
	public function setUserData(user:String = "", token:String = "")
	{
		if (logged)
			return;

		if (user == "")
		{
			data = {};
			return;
		}

		data = {
			username: user.toLowerCase(),
			developer_name: user
		};
		store = token != "" ? new GJDataStore({username: data.username, token: this.token = token}) : null;
	}

	/**
	 * Loads the User data according the registered credentials, it also overwrites `data`.
	 * NOTE: You must call this right after you call `setUserData`.
	 * @return A `Future` instance holding the new User data if the request was successful.
	 */
	public function refreshData():Future<User>
	{
		var promise:Promise<User> = new Promise<User>();
		if (!logged || token == "")
			return promise.complete(data).future;

		var req = new GJRequest().urlFromBatch([USER_AUTH(data.username, token), USER_FETCH([data.username])], true);
		req.onComplete(res -> promise.complete(data = res.responses[1].users[0]));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Registers a new Score from this User into a certain Score Table of your game.
	 * NOTE: This is the only function available for Guest Users to use.
	 * @param sort The numerical representation of your score (By example: 500).
	 * @param tag The tag that goes along with the sort value (By example: "Points" -> 500 Points).
	 * @param extra_data If there's some extra data about this Score achievement, you can set it here.
	 * @param table_id The ID of the Score Table this Score is gonna be added to.
	 * 					 (If you leave this `null`, this Score will be added to the Primary Score Table of your game)
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function addScore(sort:Int, tag:String, ?extra_data:String, ?table_id:Int):Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		if (data == {})
			return promise.complete(false).future;

		var req = new GJRequest().urlFromType(SCORES_ADD(data.username, token, '$sort $tag', sort, extra_data, table_id));
		req.onComplete(res -> promise.complete(res.success));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Gives a Trophy from this game to this User.
	 * @param trophyID The ID of the Trophy to achieve.
	 * @param removeAfter Whether to remove the Trophy after achieving it or not,
	 * 						useful when it comes to Trophy testing and stuff.
	 * 						Default is `false`.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function addTrophy(trophyID:Int, removeAfter:Bool = false):Future<Trophy>
	{
		var promise:Promise<Trophy> = new Promise<Trophy>();

		if (!logged || token == "")
		{
			promise.error("User's session is inactive or game token is missing for trophy achievement");
			return promise.future;
		}

		var requests:Array<RequestType> = [TROPHIES_ADD(data.username, token, trophyID)];
		if (removeAfter)
			requests.push(TROPHIES_REMOVE(data.username, token, trophyID));
		requests.push(TROPHIES_FETCH(data.username, token, trophyID));

		var req = new GJRequest().urlFromBatch(requests);
		req.onComplete(function(res)
		{
			var msg:Null<String> = res.responses[0].message;
			if (msg == null)
				promise.complete(res.responses[removeAfter ? 2 : 1].trophies[0])
			else
				promise.error(msg);
		});
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Obtains the highest rank this user has reached from a Score Table.
	 * @param table_id The ID of the Score Table the rank is gonna be fetched from.
	 * 					 (If you leave this `null`, the rank will be fetched from the Primary Score Table of your game)
	 * @return A `Future` instance holding the rank number if the request was successful.
	 */
	public function getScoresRank(?table_id:Int):Future<Int>
	{
		var promise:Promise<Int> = new Promise<Int>();
		getScoresList(table_id).onComplete(function(scores)
		{
			var high:Int = 0;
			for (s in scores)
				if (s.sort > high)
					high = s.sort;

			var req = new GJRequest().urlFromType(SCORES_GETRANK(high, table_id));
			req.onComplete(res -> promise.complete(res.rank));
			req.onError(e -> promise.error(e));
			req.execute(false);
		}).onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Obtains the list of Scores achieved by this User from a certain Score Table.
	 * @param table_id The ID of the Score Table the Score list is gonna be fetched from.
	 * 					 (If you leave this `null`, the Score list will be fetched from the Primary Score Table of your game)
	 * @param limit How many Scores you wanna fetch as max. Must be a value between 1-100. Leave `null` to use the default limit (10).
	 * @param betterThan If you want to fetch only the Scores that are HIGGER than a certain value, set such value here. Otherwise, leave this `null`.
	 * 						NOTE: If you set a negative value, this will fetch the Scores that are LOWER than such value instead.
	 * @return A `Future` instance holding the Scores list if the request was successful.
	 */
	public function getScoresList(?table_id:Int, ?limit:Int, ?betterThan:Int):Future<Array<Score>>
	{
		var promise:Promise<Array<Score>> = new Promise<Array<Score>>();
		var req = new GJRequest().urlFromType(SCORES_FETCH(table_id, limit, betterThan, data.username, token));
		req.onComplete(res -> promise.complete(res.scores));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Obtains the Trophies list of your game and their state according to the User's credentials.
	 * @param achieved If you want to fetch only the Trophies that are currently achieved or unachieved, you can set that up here.
	 * 					 Leave `null` if you want to fetch every Trophy without exception.
	 * @return A `Future` instance holding the Trophies list if the request was successful.
	 */
	public function getTrophiesList(?achieved:Bool):Future<Array<Trophy>>
	{
		var promise:Promise<Array<Trophy>> = new Promise<Array<Trophy>>();

		if (!logged || token == "")
		{
			promise.error("User's session is inactive or game token is missing for Trophy list fetching");
			return promise.future;
		}

		var req = new GJRequest().urlFromType(TROPHIES_FETCH(data.username, token, achieved));
		req.onComplete(res -> promise.complete(res.trophies));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Obtains a list of the Friends this User has, if `this` is a registered User.
	 * @return A `Future` instance holding the Friends list if the request was successful.
	 */
	public function getFriendsList():Future<Array<User>>
	{
		var promise:Promise<Array<User>> = new Promise<Array<User>>();

		if (!logged || token == "")
		{
			promise.error("User's session is inactive or game token is missing for Friend list fetching");
			return promise.future;
		}

		var req = new GJRequest().urlFromType(FRIENDS(data.username, token));
		req.onComplete(function(res)
		{
			var req2 = new GJRequest().urlFromType(USER_FETCH(res.friends.map(f -> Std.string(f.friend_id))));
			req2.onComplete(res2 -> promise.complete(res2.users));
			req2.onError(e -> promise.error(e));
			req2.execute(false);
		});
		req.onError(e -> promise.error(e));
		req.execute(true);

		return promise.future;
	}

	/**
	 * Disconnects User from GameJolt, if there's a session active.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function logout():Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		if (!logged || token == "")
			return promise.complete(false).future;

		var req = new GJRequest().urlFromBatch([SESSION_CLOSE(data.username, token), SESSION_CHECK(data.username, token)], true);
		req.onComplete(res -> promise.complete(logged = res.responses[1].success));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}

	/**
	 * Connects this User to GameJolt, if they're not logged in yet.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function login():Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		if (logged || token == "")
			return promise.complete(false).future;

		var req = new GJRequest().urlFromBatch([SESSION_OPEN(data.username, token), SESSION_CHECK(data.username, token)], true);
		req.onComplete(res -> promise.complete(logged = res.responses[1].success));
		req.onError(e -> promise.error(e));
		req.execute(true);
		return promise.future;
	}
}
