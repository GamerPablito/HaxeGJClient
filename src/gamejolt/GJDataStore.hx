package gamejolt;

import gamejolt.types.*;
import lime.app.Future;
import lime.app.Promise;
import sys.thread.Thread;

class GJDataStore
{
	var instance:Map<String, String> = [];
	var credentials:Null<{username:String, token:String}> = null;

	/**
	 * Creates a new `GJDataStore` instance.
	 * @param credentials Pass the user and token this instance is going to fetch data from.
	 * 						 Otherwise, the data will be fetched from the game itself.
	 */
	public function new(?credentials:{username:String, token:String})
		this.credentials = credentials;

	function getKeys():Null<Array<String>>
	{
		var keys:Null<Array<String>> = null;
		new GJRequest().urlFromType(credentials == null ? DATA_GETKEYS() : DATA_GETKEYS(null, credentials.username, credentials.token))
			.execute(false)
			.onComplete(res -> keys = res.keys.map(k -> k.key));
		return keys;
	}

	/**
	 * Uploads the local data to the GameJolt cloud and overwrites it.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function save():Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		var keys = getKeys();

		if (keys == null)
		{
			promise.complete(false);
			return promise.future;
		}

		Thread.create(function()
		{
			for (k => v in instance)
			{
				if (promise.isError)
					break;
				new GJRequest().urlFromType(credentials == null ? DATA_SET(k, v) : DATA_SET(k, v, credentials.username, credentials.token))
					.execute(false)
					.onError(e -> promise.error(e));
			}

			for (k in keys)
			{
				if (promise.isError)
					break;

				if (!instance.exists(k))
					new GJRequest().urlFromType(credentials == null ? DATA_REMOVE(k) : DATA_REMOVE(k, credentials.username, credentials.token))
						.execute(false)
						.onError(e -> promise.error(e));
			}

			if (!promise.isError)
				promise.complete(true);
		});

		return promise.future;
	}

	/**
	 * Downloads data from the GameJolt cloud to the local data.
	 * @return A `Future` instance holding the new data into a string map if the request was successful.
	 */
	public function load():Future<Map<String, String>>
	{
		var loadMap:Map<String, String> = [];
		var promise:Promise<Map<String, String>> = new Promise<Map<String, String>>();
		var keys = getKeys();

		if (keys == null)
		{
			promise.error("Failed to load keys from cloud!");
			return promise.future;
		}

		Thread.create(function()
		{
			for (k in keys)
			{
				new GJRequest().urlFromType(credentials == null ? DATA_FETCH(k) : DATA_FETCH(k, credentials.username, credentials.token))
					.execute(false)
					.onComplete(res -> loadMap.set(k, res.data))
					.onError(e -> promise.error(e));
				if (promise.isError)
					break;
			}
			if (!promise.isError)
				promise.complete(instance = loadMap);
		});
		return promise.future;
	}

	/**
	 * Removes a key and its value from the local data and GameJolt cloud data.
	 * @param key The key whose value is gonna be removed.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function remove(key:String):Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		var type:RequestType = credentials == null ? DATA_REMOVE(key) : DATA_REMOVE(key, credentials.username, credentials.token);

		new GJRequest().urlFromType(type)
			.execute(true)
			.onComplete(function(res)
			{
				if (res.success)
					instance.remove(key);
				promise.complete(res.success);
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Updates the value from a certain key, according to the Update Type you choose.
	 * @param key The whose value is gonna be updated.
	 * @param uType The Update Type the value is gonna be updated with.
	 * @return A `Future` instance holding the updated value of this key if the request was successful.
	 */
	public function update(key:String, uType:DataUpdateType):Future<String>
	{
		var promise:Promise<String> = new Promise<String>();
		new GJRequest().urlFromType(credentials == null ? DATA_UPDATE(key, uType) : DATA_UPDATE(key, uType, credentials.username, credentials.token))
			.execute(true)
			.onComplete(function(res)
			{
				instance.set(key, res.data);
				promise.complete(res.data);
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Fetches the value from a certain key, if such key exists.
	 * @param key The key whose value you wanna fetch.
	 * @return A `Future` instance holding the value of such key if the request was successful.
	 */
	public function get(key:String):Future<String>
	{
		var promise:Promise<String> = new Promise<String>();

		if (instance.exists(key))
		{
			promise.complete(instance.get(key));
			return promise.future;
		}

		new GJRequest().urlFromType(credentials == null ? DATA_FETCH(key) : DATA_FETCH(key, credentials.username, credentials.token))
			.execute(true)
			.onComplete(function(res)
			{
				instance.set(key, res.data);
				promise.complete(res.data);
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}

	/**
	 * Sets a new value for a certain key. If such key doesn't exist, it's created with the given value.
	 * @param key The key you wanna assign/overwrite the value to.
	 * @param value The new value for the key.
	 * @return A `Future` instance holding the success state of the request.
	 */
	public function set(key:String, value:String):Future<Bool>
	{
		var promise:Promise<Bool> = new Promise<Bool>();
		var type:RequestType = credentials == null ? DATA_SET(key, value) : DATA_SET(key, value, credentials.username, credentials.token);

		new GJRequest().urlFromType(type)
			.execute(true)
			.onComplete(function(res)
			{
				if (res.success)
					instance.set(key, value);
				promise.complete(res.success);
			})
			.onError(e -> promise.error(e));
		return promise.future;
	}
}
