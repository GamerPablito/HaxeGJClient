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
	 * Use `refresh()` to update.
	 */
	public var data(default, null):User = {username: "", developer_name: ""};

	/**
	 * Whether if the User is currently connected to GameJolt or not.
	 */
	public var logged(default, null):Bool = false;

	/**
	 * The Data Store of the User, it can be `null` if there are no credentials registered in.
	 */
	public var store(default, null):Null<GJDataStore> = null;

	var pingActive:Bool = true;
	var pingTrigger:Null<Timer> = null;
	var token:String = "";

	/**
	 * Creates a new `GJUser` instance.
	 */
	public function new()
	{
		Application.current.window.onFocusIn.add(() -> pingActive = true);
		Application.current.window.onFocusOut.add(() -> pingActive = false);
	}

	/**
	 * Declares new credentials for this `GJUser` instance to use. \
	 * NOTE: This won't work if the previously User registered here is still logged into GameJolt.
	 * @param user The username of the user.
	 * @param token The game token of the user. Leave blank if you wanna register as guest.
	 */
	public function setUserData(user:String = "", token:String = ""):GJUser
	{
		if (logged)
			return this;

		data = {
			username: user.toLowerCase(),
			developer_name: user
		};

		store = token != "" ? new GJDataStore({username: data.username, token: token}) : null;
		this.token = token;
		refresh();
		return this;
	}

	/**
	 * Loads the User data according the registered credentials, it also overwrites `data`.
	 * @return A `Future` instance holding the new User data if the request was successful.
	 */
	public function refresh():Future<User>
	{
		var promise:Promise<User> = new Promise<User>();

		if (token == "")
		{
			promise.error("User's game token is missing for data refreshing");
			data = {username: "", developer_name: ""};
			return promise.future;
		}

		new GJRequest().urlFromBatch([USER_AUTH(data.username, token), USER_FETCH([data.username])], true)
			.execute(true)
			.onComplete(res -> promise.complete(data = res.responses[1].users[0]))
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Registers a new Score from this User into a certain Score Table of your game.
	 * @param sort The numerical representation of your score (By example: 500).
	 * @param tag The tag that goes along with the sort value (By example: "Points" -> 500 Points).
	 * @param extra_data If there's some extra data about this Score achievement, you can set it here.
	 * @param table_id The ID of the Score Table this Score is gonna be added to.
	 * 					 (If you leave this `null`, this Score will be added to the Primary Score Table of your game)
	 * @return A `Future` instance holding the data of the submitted score if the request was successful.
	 */
	public function addScore(sort:Int, tag:String, ?extra_data:String, ?table_id:Int):Future<Score>
	{
		var promise:Promise<Score> = new Promise<Score>();
		new GJRequest().urlFromBatch([
			SCORES_ADD(data.username, token, '$sort $tag', sort, extra_data, table_id),
			SCORES_FETCH(table_id, null, sort - 1, data.username, token)
		])
			.execute(true)
			.onComplete(res -> promise.complete(Lambda.find(res.responses[1].scores, s -> sort == s.sort)))
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Gives a Trophy from this game to this User.
	 * @param trophyID The ID of the Trophy to achieve.
	 * @param removeAfter Whether to remove the Trophy after achieving it or not,
	 * 						useful when it comes to Trophy testing and stuff.
	 * 						Default is `false`.
	 * @return A `Future` instance holding the updated info of such Trophy if the request was successful.
	 */
	public function addTrophy(trophyID:Int, removeAfter:Bool = false):Future<Trophy>
	{
		var promise:Promise<Trophy> = new Promise<Trophy>();

		if (token == "")
		{
			promise.error("User's game token is missing for trophy achievement");
			return promise.future;
		}

		var requests:Array<RequestType> = [TROPHIES_ADD(data.username, token, trophyID)];
		if (removeAfter)
			requests.push(TROPHIES_REMOVE(data.username, token, trophyID));
		requests.push(TROPHIES_FETCH(data.username, token, trophyID));

		new GJRequest().urlFromBatch(requests)
			.execute(true)
			.onComplete(res -> promise.complete(res.responses[removeAfter ? 2 : 1].trophies[0]))
			.onError(e -> promise.error(e));
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

			new GJRequest().urlFromType(SCORES_GETRANK(high, table_id))
				.execute(false)
				.onComplete(res -> promise.complete(res.rank))
				.onError(e -> promise.error(e));
		});
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

		new GJRequest().urlFromType(SCORES_FETCH(table_id, limit, betterThan, data.username, token))
			.execute(true)
			.onComplete(res -> promise.complete(res.scores))
			.onError(e -> promise.error(e));
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

		new GJRequest().urlFromType(TROPHIES_FETCH(data.username, token, achieved))
			.execute(true)
			.onComplete(res -> promise.complete(res.trophies))
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Obtains a list of the Friends this User has, if `this` is a registered User.
	 * @return A `Future` instance holding the Friends list if the request was successful.
	 */
	public function getFriendsList():Future<Array<User>>
	{
		var promise:Promise<Array<User>> = new Promise<Array<User>>();

		if (token == "")
		{
			promise.error("User's game token is missing for friend list fetching");
			return promise.future;
		}

		new GJRequest().urlFromType(FRIENDS(data.username, token))
			.execute(true)
			.onComplete(res -> new GJRequest().urlFromType(USER_FETCH(res.friends.map(f -> Std.string(f.friend_id))))
				.execute(false)
				.onComplete(res2 -> promise.complete(res2.users))
				.onError(e -> promise.error(e)))
			.onError(e -> promise.error(e));

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
		{
			promise.complete(false);
			return promise.future;
		}

		new GJRequest().urlFromBatch([SESSION_CLOSE(data.username, token), SESSION_CHECK(data.username, token)])
			.execute(true)
			.onComplete(function(res)
			{
				if (res.responses[0].success && pingTrigger != null)
					pingTrigger.stop();
				promise.complete(logged = res.responses[1].success);
			})
			.onError(e -> promise.error(e));
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
		{
			promise.complete(false);
			return promise.future;
		}

		new GJRequest().urlFromBatch([SESSION_OPEN(data.username, token), SESSION_CHECK(data.username, token)])
			.execute(true)
			.onComplete(function(res)
			{
				if (res.responses[0].success)
				{
					if (pingTrigger != null)
						pingTrigger.stop();
					pingTrigger = new Timer(5000);
					pingTrigger.run = () -> new GJRequest().urlFromType(SESSION_PING(data.username, token, pingActive)).execute(true).onError(e -> logout());
				}
				promise.complete(logged = res.responses[1].success);
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}
}
