package gamejolt.formats;

/**
 * The way the score tables are fetched from your game API.
 * 
 * @param id The ID of the Score Table.
 * @param name The name of the Score Table.
 * @param description The description of the Score Table.
 * @param primary Whether if this is the Primary Score Table in your game or not.
 */
typedef ScoreTable =
{
	id:Int,
	name:String,
	description:String,
	primary:Bool
}
