package gamejolt.types;

/**
 * An enum of every single command currently available to request to GameJolt API.
 */
enum RequestType
{
	DATA_FETCH(key:String, ?username:String, ?token:String);
	DATA_GETKEYS(?username:String, ?token:String, ?pattern:String);
	DATA_REMOVE(key:String, ?username:String, ?token:String);
	DATA_SET(key:String, data:String, ?username:String, ?token:String);
	DATA_UPDATE(key:String, operation:DataUpdateType, ?username:String, ?token:String);
	FRIENDS(username:String, token:String);
	TIME;
	USER_AUTH(username:String, token:String);
	USER_FETCH(userOrIDList:Array<String>);
	SESSION_OPEN(username:String, token:String);
	SESSION_PING(username:String, token:String, active:Bool);
	SESSION_CHECK(username:String, token:String);
	SESSION_CLOSE(username:String, token:String);
	SCORES_ADD(username:String, ?token:String, score:String, sort:Int, ?extra_data:String, ?table_id:Int);
	SCORES_GETRANK(sort:Int, ?table_id:Int);
	SCORES_FETCH(?table_id:Int, ?limit:Int, ?betterThan:Int, ?username:String, ?token:String);
	SCORES_TABLES;
	TROPHIES_FETCH(username:String, token:String, ?achieved:Bool, ?trophy_id:Int);
	TROPHIES_ADD(username:String, token:String, trophy_id:Int);
	TROPHIES_REMOVE(username:String, token:String, trophy_id:Int);
}
