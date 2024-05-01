package gamejolt;

import gamejolt.formats.*;
import gamejolt.types.*;
import lime.app.Future;
import openfl.events.*;

using Lambda;
using StringTools;

class GameJolt
{
	public static var gameID:Int = 0;
	public static var gameKey:String = "";
	public static var usingMd5:Bool = true;

	public static var userName(default, set):Null<String> = null;
	public static var userToken(default, set):Null<String> = null;
	public static var logged(default, null):Bool = false;

	static var mainURL(default, never):String = 'https://api.gamejolt.com/api/game/v1_2';

	static function set_userName(value:Null<String>):Null<String>
	{
		if (value == "")
			value = null;
		return userName = value;
	}

	static function set_userToken(value:Null<String>):Null<String>
	{
		if (value == "")
			value = null;
		return userToken = value;
	}

	public static function sessionOpen():Future<Bool>
		return sendRequest([USER_AUTH(userName, userToken), SESSION_OPEN(userName, userToken)]).then(res -> Future.withValue(logged = res.success));

	public static function sessionClose():Future<Bool>
		return sendRequest([SESSION_CLOSE(userName, userToken)]).then(res -> Future.withValue(logged = !res.success));

	public static function sessionCheck():Future<Bool>
		return sendRequest([SESSION_CHECK(userName, userToken)]).then(res -> Future.withValue(logged = res.success));

	public static function sessionPing():Future<Bool>
		return sessionCheck().then(res -> sendRequest([SESSION_PING(userName, userToken, true)])).then(res2 -> Future.withValue(res2.success));

	public static function addScore(sort:Int, tag:String, ?extra_data:String, ?table_id:Int):Future<Bool>
		return sendRequest([SCORES_ADD(userName, userToken, '$tag: $sort', sort, extra_data, table_id)]).then(res -> Future.withValue(res.success));

	public static function addTrophy(trophy_id:Int):Future<Bool>
		return sendRequest([TROPHIES_ADD(userName, userToken, trophy_id)]).then(res -> Future.withValue(res.success));

	public static function removeTrophy(trophy_id:Int):Future<Bool>
		return sendRequest([TROPHIES_REMOVE(userName, userToken, trophy_id)]).then(res -> Future.withValue(res.success));

	public static function getUserFriends():Future<Array<User>>
		return sendRequest([FRIENDS(userName, userToken)]).then(res -> fetchUsersInfo(res.friends.map(f -> Std.string(f.friend_id))));

	public static function getUserInfo():Future<User>
		return sendRequest([USER_FETCH([userName])]).then(res -> Future.withValue(res.users[0]));

	public static function getUserTrophies():Future<Array<Trophy>>
		return sendRequest([TROPHIES_FETCH(userName, userToken)]).then(res -> Future.withValue(res.trophies));

	public static function getScoresList(?table_id:Int, fromUser:Bool = false):Future<Array<Score>>
		return sendRequest([SCORES_FETCH(table_id, fromUser ? userName : null, fromUser ? userToken : null)]).then(res -> Future.withValue(res.scores));

	public static function getScoreRank(sort:Int, ?table_id:Int):Future<Int>
		return sendRequest([SCORES_GETRANK(sort, table_id)]).then(res -> Future.withValue(res.rank));

	public static function getScoreTables():Future<Array<ScoreTable>>
		return sendRequest([SCORES_TABLES]).then(res -> Future.withValue(res.tables));

	public static function fetchUsersInfo(userOrIDList:Array<String>):Future<Array<User>>
		return sendRequest([USER_FETCH(userOrIDList)]).then(res -> Future.withValue(res.users));

	public static function getServerTime():Future<Date>
		return sendRequest([TIME]).then(function(res)
		{
			var month:String = '${res.month < 10 ? "0" : ""}${res.month}';
			var day:String = '${res.day < 10 ? "0" : ""}${res.day}';

			var hour:String = '${res.hour < 10 ? "0" : ""}${res.hour}';
			var minute:String = '${res.minute < 10 ? "0" : ""}${res.minute}';
			var second:String = '${res.second < 10 ? "0" : ""}${res.second}';

			return Future.withValue(Date.fromString('${res.year}-${month}-${day} ${hour}:${minute}:${second}'));
		});

	public static function getDataStore(key:String, fromUser:Bool = false):Future<String>
	{
		if (fromUser && (userName == null || userToken == null))
		{
			var err:String = "Request Error: User Credentials are not declared for Data Store command 'GET'";
			#if debug Sys.println('$err\n'); #end
			return Future.withError(err).then((_) -> Future.withValue(""));
		}
		return sendRequest([DATA_FETCH(key, userName, userToken)]).then(res -> Future.withValue(res.data));
	}

	public static function setDataStore(key:String, value:String, toUser:Bool = false):Future<Bool>
	{
		if (toUser && (userName == null || userToken == null))
		{
			var err:String = "Request Error: User Credentials are not declared for Data Store command 'SET'";
			#if debug Sys.println('$err\n'); #end
			return Future.withError(err).then((_) -> Future.withValue(false));
		}
		return sendRequest([DATA_SET(key, value, userName, userToken)]).then(res -> Future.withValue(res.success));
	}

	public static function updateDataStore(key:String, uType:DataUpdateType, toUser:Bool = false):Future<Bool>
	{
		if (toUser && (userName == null || userToken == null))
		{
			var err:String = "Request Error: User Credentials are not declared for Data Store command 'UPDATE'";
			#if debug Sys.println('$err\n'); #end
			return Future.withError(err).then((_) -> Future.withValue(false));
		}
		return sendRequest([DATA_UPDATE(key, uType, userName, userToken)]).then(res -> Future.withValue(res.success));
	}

	public static function fetchDataStore(fromUser:Bool = false):Future<Array<String>>
	{
		if (fromUser && (userName == null || userToken == null))
		{
			var err:String = "Error: User Credentials are not declared for Data Store command 'GET_KEYS'";
			#if debug Sys.println('$err\n'); #end
			return Future.withError(err).then((_) -> Future.withValue([]));
		}
		return sendRequest([DATA_GETKEYS(userName, userToken)]).then(res -> Future.withValue(res.keys.map(k -> k.key)));
	}

	public static function sendRequest(calls:Array<RequestType>, breakOnError:Bool = true, parallel:Bool = false):Future<Response>
	{
		var url:String = sign('$mainURL${calls.length == 1 ? parseType(calls[0]) : '/batch?game_id=$gameID&parallel=$parallel&break_on_error=$breakOnError${calls.map(c -> '&requests[]=${parseType(c, true)}').join('')}'}');
		var promise = new lime.app.Promise<Response>();
		var loader = new openfl.net.URLLoader();

		loader.addEventListener(Event.COMPLETE, function(complete)
		{
			var response:Response = formatResponse(cast haxe.Json.parse(loader.data).response);
			if (response.message == null)
			{
				promise.complete(response);
				#if debug Sys.println("Success!\n"); #end
			}
			else
			{
				var err:String = 'Response Error: ${response.message}';
				promise.error(err);
				#if debug Sys.println('$err\n'); #end
			}
		});

		#if debug
		loader.addEventListener(Event.OPEN, function(open)
		{
			var reqLine:String = url.replace('$mainURL/', '');
			reqLine = reqLine.replace(reqLine.substring(reqLine.lastIndexOf('&signature=')), "");
			Sys.println('Requesting: $reqLine');
		});
		loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, code -> Sys.println('Request ended with status code ${code.status}'));
		#end

		loader.addEventListener(ProgressEvent.PROGRESS, progress -> promise.progress(Math.round(progress.bytesLoaded), Math.round(progress.bytesTotal)));
		loader.addEventListener(IOErrorEvent.IO_ERROR, function(ioError)
		{
			var err:String = 'IO Error: ${ioError.text}';
			promise.error(err);
			#if debug Sys.println('$err\n'); #end
		});
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(securityError)
		{
			var err:String = 'Security Error: ${securityError.text}';
			promise.error(err);
			#if debug Sys.println('$err\n'); #end
		});
		loader.load(new openfl.net.URLRequest(url));
		return promise.future;
	}

	static function formatResponse(oldRes:Response):Response
	{
		var res:Response = oldRes;
		if (res.users != null)
			res.users.iter(u -> u.avatar_url = '${u.avatar_url.substring(0, 32)}1000${u.avatar_url.substr(34)}'.replace(".jpg", ".png")
				.replace(".webp", ".png"));
		if (res.trophies != null)
			res.trophies.iter(function(t)
			{
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
					newUrl = '${t.image_url.substring(0, 37)}1000${t.image_url.substr(40)}'.replace(".jpg", ".png").replace(".webp", ".png");
				else
				{
					newUrl = "https://s.gjcdn.net/assets/";
					newUrl += switch (t.image_url.substring(24).replace('.jpg', ''))
					{
						case "trophy-bronze-1": "9c2c91d0";
						case "trophy-silver-1": "b46e352e";
						case "trophy-gold-1": "363ce2dc";
						case "trophy-platinum-1": "92e5330d";
						default: "";
					};
					newUrl += ".png";
				}
				t.image_url = newUrl;
			});
		if (res.responses != null)
			res.responses.iter(res2 -> res2 = formatResponse(res2));
		return res;
	}

	static function parseType(request:RequestType, signed:Bool = false):String
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
			case DATA_GETKEYS(username, token, pattern):
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

		var urlSection:String = '/$command${action != "" ? '/$action' : ""}?game_id=$gameID${[for (k => v in params) '&$k=$v'].join("")}';
		if (signed)
			urlSection = sign(urlSection).urlEncode();
		return urlSection;
	}

	static function sign(daUrl:String):String
	{
		var urlEncode:String = daUrl + gameKey;
		return '$daUrl&signature=${usingMd5 ? haxe.crypto.Md5.encode(urlEncode) : haxe.crypto.Sha1.encode(urlEncode)}';
	}
}
