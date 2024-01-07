package gamejolt;

import gamejolt.formats.*;
import lime.app.Future;
import lime.app.Promise;

class GJGame
{
	/**
	 * The Data Store of the User, it can be `null` if there are no credentials registered in.
	 */
	public var store(default, null):GJDataStore = new GJDataStore();

	/**
	 * Creates a new `GJGame` instance.
	 */
	public function new() {}

	/**
	 * Obtains the data from a group of Users according to the username or ID they're registered
	 * @param userOrIDList The list of the usernames or IDs of the users whose data you wanna fetch.
	 * 						 NOTE: The list must be, or ONLY usernames, or ONLY IDs. Not both of them, otherwise it won't work as expected.
	 * @return A `Future` instance holding the User(s) data list if the request was successful.
	 */
	public function getUserData(userOrIDList:Array<String>):Future<Array<User>>
	{
		var promise:Promise<Array<User>> = new Promise<Array<User>>();

		new GJRequest().urlFromType(USER_FETCH(userOrIDList))
			.execute(true)
			.onComplete(res -> promise.complete(res.users))
			.onError(e -> promise.error(e));

		return promise.future;
	}

	/**
	 * Obtains all the Score Tables registered in your game, along with the Scores registered in them.
	 * @param limit How many scores you wanna retrieve from each Table, must be a value from 1-100.
	 * 				 Leave `null` if you wanna use the default value (10).
	 * @return A `Future` instance holding the Score Tables data and their Scores if the request was successful.
	 */
	public function getScoreTables(?limit:Int):Future<Array<ScoreTable>>
	{
		var promise:Promise<Array<ScoreTable>> = new Promise<Array<ScoreTable>>();

		new GJRequest().urlFromType(SCORES_TABLES)
			.execute(true)
			.onComplete(function(res)
			{
				var tables:Array<ScoreTable> = [];
				for (t in res.tables)
					if (!promise.isError)
						new GJRequest().urlFromType(SCORES_FETCH(t.id, limit))
							.execute(false)
							.onComplete(function(res2)
							{
								t.scores = res2.scores;
								tables.push(t);
							})
							.onError(e -> promise.error(e));

				if (!promise.isError)
					promise.complete(tables);
			})
			.onError(e -> promise.error(e));

		return promise.future;
	}

	/**
	 * Gets the actual time and date of the GameJolt server
	 * @return A `Future` instance holding the structured data if the request was successful.
	 */
	public function getServerTime():Future<String>
	{
		var promise:Promise<String> = new Promise<String>();

		new GJRequest().urlFromType(TIME)
			.execute(true)
			.onComplete(function(res)
			{
				var dayWeek:String = switch (Date.fromTime(res.timestamp * 1000).getDay())
				{
					case 0: "Sunday";
					case 1: "Monday";
					case 2: "Tuesday";
					case 3: "Wednesday";
					case 4: "Thursday";
					case 5: "Friday";
					case 6: "Saturday";
					default: "";
				}
				promise.complete('${res.timezone} | $dayWeek, ${res.day}/${res.month}/${res.year} | ${res.hour}:${res.minute}:${res.second}');
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}
}
