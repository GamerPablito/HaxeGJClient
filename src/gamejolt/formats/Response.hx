package gamejolt.formats;

/**
 * This is how GameJolt API responses are formatted like.
 */
@:structInit
class Response {
	// General
	public var success:Bool = false;
	@:optional public var message:String = "No successful response has been received yet";
	// User Fetching
	@:optional public var users:Array<User>;
	// Trophies Fetching
	@:optional public var trophies:Array<Trophy>;
	// Scores Fetching
	@:optional public var scores:Array<Score>;
	@:optional public var tables:Array<ScoreTable>;
	@:optional public var rank:Int;
	// Friends Fetching
	@:optional public var friends:Array<{friend_id:Int}>;
	// Data Store Fetching
	@:optional public var keys:Array<{key:String}>;
	@:optional public var data:String;
	// Time Fetching
	@:optional public var timestamp:Int;
	@:optional public var timezone:String;
	@:optional public var year:Int;
	@:optional public var month:Int;
	@:optional public var day:Int;
	@:optional public var hour:Int;
	@:optional public var minute:Int;
	@:optional public var second:Int;
	// Batch Reception
	@:optional public var responses:Array<Response>;
}
