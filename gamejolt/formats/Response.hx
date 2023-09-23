package gamejolt.formats;

/**
 * This is how GameJolt API responses are formatted like.
 */
typedef Response = {
	// General
	success:Bool,
	?message:String,
	// User Fetching
	?users:Array<User>,
	// Trophies Fetching
	?trophies:Array<Trophy>,
	// Scores Fetching
	?scores:Array<Score>,
	?tables:Array<ScoreTable>,
	?rank:Int,
	// Friends Fetching
	?friends:Array<{friend_id:Int}>,
	// Data Store Fetching
	?keys:Array<{key:String}>,
	?data:String,
	// Time Fetching
	?timestamp:Int,
	?timezone:String,
	?year:Int,
	?month:Int,
	?day:Int,
	?hour:Int,
	?minute:Int,
	?second:Int,
	// Batch Reception
	?responses:Array<Response>
}
