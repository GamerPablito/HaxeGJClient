package gamejolt.formats;

/**
 * The way the user data is fetched from the GameJolt API.
 * 
 * @param id The ID of the User.
 * @param type The cathegory the User is cataloged like in GameJolt.
 * @param username The username of the User. (Also available for guests).
 * @param avatar_url The link of the avatar of the User.
 * @param signed_up A short description about how long the User have been in GameJolt.
 * @param signed_up_timestamp A long time stamp (in seconds) of when the User signed up.
 * @param last_logged_in A short description about the last time the User was found active in GameJolt.
 * @param last_logged_in_timestamp A long time stamp (in seconds) of the last time the User logged in GameJolt.
 * @param status The actual status of the User.
 * @param developer_name The display name of the User. (Also available for guests).
 * @param developer_website The website of the User.
 * @param developer_description The description of the User.
 */
@:structInit
class User
{
	@:optional public var id:Int;
	@:optional public var type:String;
	public var username:String = "";
	@:optional public var avatar_url:String;
	@:optional public var signed_up:String;
	@:optional public var signed_up_timestamp:Int;
	@:optional public var last_logged_in:String;
	@:optional public var last_logged_in_timestamp:Int;
	@:optional public var status:String;
	public var developer_name:String = "";
	@:optional public var developer_website:String;
	@:optional public var developer_description:String;
}
