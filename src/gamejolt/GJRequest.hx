package gamejolt;

import gamejolt.formats.Response;
import gamejolt.types.*;
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
 * But it's better to use the functions already made in there if you don't know what you're doing.
 * @see The [GameJolt API page](https://gamejolt.com/game-api) to see more about how commands work.
 */
class GJRequest {
	/**
	 * If `true`, requests will use `Md5` encryptation when creating URLs, otherwise they'll use `Sha1` encryptation.
	 */
	public static var useMd5:Bool = true;

	/**
	 * The current URL this request contains to process.
	 * Can be assigned/overwritten using `urlFromType` or `urlFromBatch`.
	 */
	public var url(default, null):String = "";

	/**
	 * Whether is this request is currently in process or not.
	 */
	public var isProcessing(get, never):Bool;

	/**
	 * The last response received by the URL processing.
	 */
	public var lastResponse(default, null):Response = {success: false, message: "No response was requested yet"};

	/**
	 * Optional callback for when the processing ends up with success.
	 */
	public var onSuccess(default, set):Null<Response->Void> = null;

	/**
	 * Optional callback for when the processing ends up with an error.
	 */
	public var onError(default, set):Null<String->Void> = null;

	var mainURL(default, never):String = "https://api.gamejolt.com/api/game/v1_2";
	var process:Null<Future<Response>> = null;

	public function new() {}

	/**
	 * Makes images to look better when fetched
	 */
	function formatResponse(res:Response) {
		if (res.users != null)
			res.users.iter(function(u) {
				var newPFP = u.avatar_url.substring(0, 32);
				newPFP += '1000';
				newPFP += u.avatar_url.substr(34);
				newPFP = newPFP.replace(".jpg", ".png");
				u.avatar_url = newPFP;
			});
		if (res.trophies != null)
			res.trophies.iter(function(t) {
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
			});
	}

	function startProcess() {
		var promise = new Promise<Response>();
		var action = '${url.substring(mainURL.length + 1, url.indexOf("?"))}';

		var command:Http = new Http(url);
		command.onData = function(req) {
			var daResponse:Response = cast Json.parse(req).response;
			if (daResponse.message != null) {
				lastResponse = {
					success: false,
					message: '"$action" => ${daResponse.message}'
				};
				promise.error(lastResponse.message);
				return;
			}

			formatResponse(daResponse);
			if (daResponse.responses != null)
				daResponse.responses.iter(res -> formatResponse(res));
			promise.complete(lastResponse = daResponse);
		};
		command.onError = function(error) {
			lastResponse = {
				success: false,
				message: '"$action" => $error'
			};
			promise.error(lastResponse.message);
		};

		process = promise.future;
		if (onSuccess != null)
			process.onComplete(onSuccess);
		if (onError != null)
			process.onError(onError);

		command.request(false);
		process = null;
	}

	/**
	 * Executes the current URL in a Syncronous way.
	 */
	public function execute() {
		if (isProcessing)
			return;

		startProcess();
	}

	/**
	 * Executes the current URL in an Asyncronous way.
	 */
	public function executeAsync() {
		if (isProcessing)
			return;

		Thread.create(() -> startProcess());
	}

	function get_isProcessing():Bool
		return process != null;

	/**
	 * Assigns/Overwrites the URL for this request using a batch call made of a list of `RequestType` subrequests.
	 * @param requests The list of `RequestType` items for URL construction.
	 * @param parallel Whether you want the subrequests to be executed in order or not.
	 * @param breakOnError Whether you want this to drop an error if one of the subrequests fail or not.
	 * @return This `GJRequest` instance.
	 */
	public function urlFromBatch(requests:Array<RequestType>, parallel:Bool = false, breakOnError:Bool = true):GJRequest {
		var newURL = '$mainURL/batch?game_id=${GJClient.game.id}&parallel=$parallel&break_on_error=$breakOnError';
		requests.iter(r -> newURL += '&requests[]=${parseType(r, true)}');
		url = sign(newURL);
		return this;
	}

	/**
	 * Assigns/Overwrites the URL for this request using a `RequestType`.
	 * @param request The type of call you wanna assign.
	 * @return This `GJRequest` instance.
	 */
	public function urlFromType(request:RequestType):GJRequest {
		url = sign('$mainURL${parseType(request)}');
		return this;
	}

	function parseType(request:RequestType, signed:Bool = false):String {
		var command:String = "";
		var action:String = "";
		var params:Map<String, String> = [];
		var needsUser:Bool = true;
		var needsToken:Bool = true;

		switch (request) {
			case DATA_FETCH(key, userRequired):
				command = "data-store";
				params.set("key", key);
				needsUser = userRequired;
			case DATA_GETKEYS(userRequired, pattern):
				command = "data_store";
				action = "get-keys";
				if (pattern != null)
					params.set("pattern", pattern);
				needsUser = userRequired;
			case DATA_REMOVE(key, userRequired):
				command = "data-store";
				action = "remove";
				params.set("key", key);
				needsUser = userRequired;
			case DATA_SET(key, data, userRequired):
				command = "data-store";
				action = "set";
				params.set("key", key);
				params.set("data", data);
				needsUser = userRequired;
			case DATA_UPDATE(key, operation, userRequired):
				command = "data-store";
				action = "update";
				params.set("key", key);
				needsUser = userRequired;
				switch (operation) {
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
			case FRIENDS:
				command = "friends";
			case TIME:
				command = "time";
				needsUser = false;
			case USER_AUTH(account):
				command = "users";
				action = "auth";
				if (account != null) {
					needsUser = false;
					params.set("username", account.user);
					params.set("user_token", account.token);
				}
			case USER_FETCH(userOrIDList):
				command = "users";
				if (userOrIDList != null) {
					needsUser = false;
					params.set(userOrIDList.exists(u -> Std.parseInt(u) == null) ? "username" : "user_id", '${userOrIDList.join(",")}');
				} else
					needsToken = false;
			case SESSION_OPEN:
				command = "sessions";
				action = "open";
			case SESSION_PING(active):
				command = "sessions";
				action = "ping";
				params.set("status", active ? "active" : "idle");
			case SESSION_CHECK:
				command = "sessions";
				action = "check";
			case SESSION_CLOSE:
				command = "sessions";
				action = "close";
			case SCORES_ADD(score, sort, extra_data, table_id):
				command = "scores";
				action = "add";
				params.set("score", score);
				params.set("sort", '$sort');
				if (extra_data != null)
					params.set("extra_data", extra_data);
				if (table_id != null)
					params.set("table_id", '$table_id');
			case SCORES_GETRANK(sort, table_id):
				command = "scores";
				action = "get-rank";
				params.set("sort", '$sort');
				if (table_id != null)
					params.set("table_id", '$table_id');
			case SCORES_FETCH(table_id, limit, betterThan):
				command = "scores";
				if (table_id != null)
					params.set("table_id", '$table_id');
				if (limit != null) {
					if (limit < 1)
						limit = 1;
					if (limit > 100)
						limit = 100;
					params.set("limit", '$limit');
				}
				if (betterThan != null)
					params.set(betterThan < 0 ? "worse_than" : "better_than", '${Math.abs(betterThan)}');
			case SCORES_TABLES:
				command = "scores";
				action = "tables";
				needsUser = false;
			case TROPHIES_FETCH(achieved, trophy_id):
				command = "trophies";
				if (achieved != null)
					params.set("achieved", '$achieved');
				if (trophy_id != null)
					params.set("trophy_id", '$trophy_id');
			case TROPHIES_ADD(trophy_id):
				command = "trophies";
				action = "add";
				params.set("trophy_id", '$trophy_id');
			case TROPHIES_REMOVE(trophy_id):
				command = "trophies";
				action = "remove";
				params.set("trophy_id", '$trophy_id');
		}

		var account:Account = GJClient.account;
		if (needsUser && account.user != "") {
			params.set(command == "scores" && action == "add" && account.token == "" ? "guest" : "username", account.user);
			if (needsToken && account.token != "")
				params.set("user_token", account.token);
		}

		var urlSection = '/$command${action != "" ? '/$action' : ""}?game_id=${GJClient.game.id}';
		for (k => v in params)
			urlSection += '&$k=$v';
		if (signed)
			urlSection = sign(urlSection).urlEncode();
		return urlSection;
	}

	function sign(daUrl:String):String {
		var urlEncode = daUrl + GJClient.game.key;
		return '$daUrl&signature=${useMd5 ? Md5.encode(urlEncode) : Sha1.encode(urlEncode)}';
	}

	function set_onSuccess(value:Null<Response->Void>):Null<Response->Void> {
		if (isProcessing)
			return onSuccess;
		return onSuccess = value;
	}

	function set_onError(value:Null<String->Void>):Null<String->Void> {
		if (isProcessing)
			return onError;
		return onError = value;
	}
}
