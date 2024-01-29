package gamejolt;

import gamejolt.formats.Response;
import gamejolt.types.RequestType;
import haxe.Http;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import lime.app.Future;
import lime.app.Promise;
import sys.thread.Thread;

using Lambda;
using StringTools;

/**
 * Official class to create communication calls for GameJolt API. \
 * You're even able to use instances of this class individually without the need of the `GJClient`. \
 * However, the game credentials for instances of `this` must be set in `GJClient.apidata` to be used.
 * @see The [GameJolt API page](https://gamejolt.com/game-api) to see more about how commands work.
 */
class GJRequest extends Future<Response>
{
	/**
	 * If `true`, requests will use `Md5` encryptation when creating URLs, otherwise they'll use `Sha1` encryptation.
	 */
	public static var useMd5:Bool = true;

	/**
	 * Whether if this request is using `Md5` or `Sha1` encryptation when creating URLs.
	 */
	public var isUsingMd5(default, never):Bool = useMd5;

	/**
	 * The current URL this request contains to process.
	 * Can be assigned/overwritten using `urlFromType` or `urlFromBatch`.
	 */
	public var url(default, null):String = "";

	/**
	 * Whether if this currently being executed or not.
	 */
	public var executing(default, null):Bool;

	var ignoreSubErrors:Bool = false;
	var mainURL(default, never):String = "https://api.gamejolt.com/api/game/v1_2";

	public function new()
		super();

	/**
	 * Assigns/Overwrites the URL for this request using a batch call made of a list of `RequestType` subrequests. \
	 * NOTE: This will not work if this request is in process to be finished.
	 * 
	 * @param requests The list of `RequestType` items for URL construction. You cannot assign more than 50, so be careful!
	 * @param breakOnError Whether you want this to drop an error if one of the subrequests fail or not.
	 * @param parallel Whether you want the subrequests to be executed in order (false), or everything at once (true).
	 * @return This `GJRequest` instance.
	 */
	public function urlFromBatch(requests:Array<RequestType>, breakOnError:Bool = false, parallel:Bool = false):GJRequest
	{
		var newURL = '$mainURL/batch?game_id=${GJClient.apidata.id}&parallel=$parallel&break_on_error=${ignoreSubErrors == !breakOnError}';
		requests.iter(r -> newURL += '&requests[]=${parseType(r, true)}');
		url = sign(newURL);
		return this;
	}

	/**
	 * Assigns/Overwrites the URL for this request using a `RequestType`.
	 * NOTE: This will not work if this request is in process to be finished.
	 * @param request The type of call you wanna assign.
	 * @return This `GJRequest` instance.
	 */
	public function urlFromType(request:RequestType):GJRequest
	{
		url = sign('$mainURL${parseType(request)}');
		return this;
	}

	public function execute(async:Bool)
	{
		isComplete = isError = false;
		error = value = null;
		executing = true;

		var promise = new Promise<Response>();
		promise.future = this;

		function process()
		{
			var action = '${url.substring(mainURL.length + 1, url.indexOf("?"))}';
			var command:Http = new Http(url);

			command.onData = function(req)
			{
				var res:Response = cast Json.parse(req).response;
				if (res.message != null)
				{
					promise.error('"$action" => ${res.message}');
					return;
				}
				else if (res.responses != null && !ignoreSubErrors)
				{
					var counter:Int = -1;
					var fetchedError = res.responses.find(function(res2)
					{
						counter++;
						return res2.message != null;
					});
					if (fetchedError != null)
					{
						promise.error('"batch[$counter]" => ${fetchedError.message}');
						return;
					}
				}

				formatResponse(res);
				promise.complete(res);
			};
			command.onError = error -> promise.error('"$action" => $error');
			command.request(false);
			executing = false;
		}

		async ? process() : Thread.create(process);
	}

	function parseType(request:RequestType, signed:Bool = false):String
	{
		var command:String = "";
		var action:String = "";
		var params:Map<String, String> = [];

		switch (request)
		{
			case DATA_FETCH(key, username, token):
				command = "data-store";
				params.set("key", key);
				if (username != null && username != "" && token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
			case DATA_GETKEYS(pattern, username, token):
				command = "data-store";
				action = "get-keys";
				if (pattern != null)
					params.set("pattern", pattern);
				if (username != null && username != "" && token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
			case DATA_REMOVE(key, username, token):
				command = "data-store";
				action = "remove";
				params.set("key", key);
				if (username != null && username != "" && token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
			case DATA_SET(key, data, username, token):
				command = "data-store";
				action = "set";
				params.set("key", key);
				params.set("data", data);
				if (username != null && username != "" && token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
			case DATA_UPDATE(key, operation, username, token):
				command = "data-store";
				action = "update";
				params.set("key", key);
				if (username != null && username != "" && token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
				switch (operation)
				{
					case Add(n):
						params.set('operation', 'add');
						params.set('value', '$n');
					case Substract(n):
						params.set('operation', 'substract');
						params.set('value', '$n');
					case Multiply(n):
						params.set('operation', 'multiply');
						params.set('value', '$n');
					case Divide(n):
						params.set('operation', 'divide');
						params.set('value', '$n');
					case Append(t):
						params.set('operation', 'append');
						params.set('value', t);
					case Prepend(t):
						params.set('operation', 'prepend');
						params.set('value', t);
				}
			case FRIENDS(username, token):
				command = "friends";
				params.set("username", username);
				params.set("user_token", token);
			case TIME:
				command = "time";
			case USER_AUTH(username, token):
				command = "users";
				action = "auth";
				params.set("username", username);
				params.set("user_token", token);
			case USER_FETCH(userOrIDList):
				command = "users";
				if (userOrIDList != [])
					params.set(Std.parseInt(userOrIDList[0]) == null ? "username" : "user_id", userOrIDList.join(","));
			case SESSION_OPEN(username, token):
				command = "sessions";
				action = "open";
				params.set("username", username);
				params.set("user_token", token);
			case SESSION_PING(username, token, active):
				command = "sessions";
				action = "ping";
				params.set("status", active ? "active" : "idle");
				params.set("username", username);
				params.set("user_token", token);
			case SESSION_CHECK(username, token):
				command = "sessions";
				action = "check";
				params.set("username", username);
				params.set("user_token", token);
			case SESSION_CLOSE(username, token):
				command = "sessions";
				action = "close";
				params.set("username", username);
				params.set("user_token", token);
			case SCORES_ADD(username, token, score, sort, extra_data, table_id):
				command = "scores";
				action = "add";
				params.set("score", score);
				params.set("sort", '$sort');
				if (extra_data != null && extra_data != "")
					params.set("extra_data", extra_data);
				if (table_id != null)
					params.set("table_id", '$table_id');
				if (token != null && token != "")
				{
					params.set("username", username);
					params.set("user_token", token);
				}
				else
					params.set("guest", username);
			case SCORES_GETRANK(sort, table_id):
				command = "scores";
				action = "get-rank";
				params.set("sort", '$sort');
				if (table_id != null)
					params.set("table_id", '$table_id');
			case SCORES_FETCH(table_id, limit, betterThan, username, token):
				command = "scores";
				if (table_id != null)
					params.set("table_id", '$table_id');
				if (limit != null)
				{
					if (limit < 1)
						limit = 1;
					if (limit > 100)
						limit = 100;
					params.set("limit", '$limit');
				}
				if (betterThan != null)
					params.set(betterThan < 0 ? "worse_than" : "better_than", '${Math.abs(betterThan)}');
				if (username != null && username != "")
				{
					if (token != null && token != "")
					{
						params.set("username", username);
						params.set("user_token", token);
					}
					else
						params.set("guest", username);
				}
			case SCORES_TABLES:
				command = "scores";
				action = "tables";
			case TROPHIES_FETCH(username, token, achieved, trophy_id):
				command = "trophies";
				if (achieved != null)
					params.set("achieved", '$achieved');
				if (trophy_id != null)
					params.set("trophy_id", '$trophy_id');
				params.set("username", username);
				params.set("user_token", token);
			case TROPHIES_ADD(username, token, trophy_id):
				command = "trophies";
				action = "add";
				params.set("trophy_id", '$trophy_id');
				params.set("username", username);
				params.set("user_token", token);
			case TROPHIES_REMOVE(username, token, trophy_id):
				command = "trophies";
				action = "remove";
				params.set("trophy_id", '$trophy_id');
				params.set("username", username);
				params.set("user_token", token);
		}

		var urlSection = '/$command${action != "" ? '/$action' : ""}?game_id=${GJClient.apidata.id}';
		for (k => v in params)
			urlSection += '&$k=$v';
		if (signed)
			urlSection = sign(urlSection).urlEncode();
		return urlSection;
	}

	/**
	 * Makes images to look better when fetched
	 */
	function formatResponse(res:Response)
	{
		if (res.users != null)
			res.users.iter(function(u)
			{
				var newPFP = u.avatar_url.substring(0, 32);
				newPFP += '1000';
				newPFP += u.avatar_url.substr(34);
				newPFP = newPFP.replace(".jpg", ".png");
				u.avatar_url = newPFP;
			});
		if (res.trophies != null)
			res.trophies.iter(function(t)
			{
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
				{
					newUrl = t.image_url.substring(0, 37);
					newUrl += '1000';
					newUrl += t.image_url.substr(40);
					newUrl = newUrl.replace(".jpg", ".png");
				}
				else
				{
					newUrl = "https://s.gjcdn.net/assets/";
					switch (t.image_url.substring(24).replace('.jpg', ''))
					{
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
			});
		if (res.responses != null)
			res.responses.iter(res2 -> formatResponse(res2));
	}

	function sign(daUrl:String):String
	{
		var urlEncode = daUrl + GJClient.apidata.key;
		return '$daUrl&signature=${isUsingMd5 ? Md5.encode(urlEncode) : Sha1.encode(urlEncode)}';
	}
}
