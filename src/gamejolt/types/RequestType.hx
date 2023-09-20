package gamejolt.types;

/**
 * An enum of every single command currently available to request to GameJolt API.
 */
enum RequestType {
	DATA_FETCH(key:String, userRequired:Bool);
	DATA_GETKEYS(userRequired:Bool, ?pattern:String);
	DATA_REMOVE(key:String, userRequired:Bool);
	DATA_SET(key:String, data:String, userRequired:Bool);
	DATA_UPDATE(key:String, operation:DataUpdateType, userRequired:Bool);
	FRIENDS;
	TIME;
	USER_AUTH(?account:gamejolt.formats.Account);
	USER_FETCH(?userOrIDList:Array<String>);
	SESSION_OPEN;
	SESSION_PING(active:Bool);
	SESSION_CHECK;
	SESSION_CLOSE;
	SCORES_ADD(score:String, sort:Int, ?extra_data:String, ?table_id:Int);
	SCORES_GETRANK(sort:Int, ?table_id:Int);
	SCORES_FETCH(?table_id:Int, ?limit:Int, ?betterThan:Int);
	SCORES_TABLES;
	TROPHIES_FETCH(?achieved:Bool, ?trophy_id:Int);
	TROPHIES_ADD(trophy_id:Int);
	TROPHIES_REMOVE(trophy_id:Int);
}
