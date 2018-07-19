package frost2d;

import google.WebFontLoader;
import howler.Howl;
import js.Browser;
import js.Error;
import js.html.Image;
import js.html.XMLHttpRequest;

/** A system for loading assets in an organized manner. */
class Loader {
	
	/** Whether or not the tasks have been started. */
	private var started:Bool = false;
	/** All tasks, which are essentially callbacks that receive an ID. */
	private var tasks:Array<Int->Void> = [];
	
	/** Percentage of tasks that have been completed. */
	public var progress(default, null):Float = 0;
	/** Callback for when progress is made. */
	public var onProgress:Void->Void;
	/** Whether or not all tasks are complete (new tasks can still be created). */
	public var complete(default, null):Bool = false;
	/** Callback for when all tasks are complete. */
	public var onComplete:Void->Void;
	
	public function new() {}
	
	/** Starts the tasks, triggering the loading of any assets. */
	public function start():Void {
		if (started) #if debug throw new Error("Already started loader!"); #else return; #end
		started = true;
		if (tasks.length > 0) {
			for (i in 0 ... tasks.length) tasks[i](i);
		} else test();
	}
	
	/**
	 * Creates a new task, which is a callback that receives an ID.
	 * @param	task	Callback for when the task is started.
	 */
	public function createTask(task:Int->Void):Void {
		if (task != null && tasks.indexOf(task) < 0) {
			tasks.push(task);
			if (started) task(tasks.length - 1);
		}
	}
	
	/**
	 * Marks the task with the specifified ID as finished.
	 * @param	id	ID of the task.
	 */
	public function endTask(id:Int):Void {
		if (tasks[id] != null) {
			tasks[id] = null;
			test();
		}
	}
	
	/** Tests what tasks are complete, sets variables, and triggers callbacks. */
	private function test():Void {
		if (!started || complete) return;
		var p:Float = 1;
		if (tasks.length > 0) {
			var n:Float = 0;
			for (task in tasks) {
				if (task == null) n++;
			}
			p = n / tasks.length;
		}
		if (progress != p) {
			progress = p;
			if (onProgress != null) onProgress();
		}
		if (progress == 1) {
			complete = true;
			if (onComplete != null) onComplete();
		}
	}
	
	/**
	 * Loads an image from the specified path. The returned image is usable once it loads.
	 * @param	path	Path to the image.
	 * @param	onLoad	Callback for when the image loads.
	 * @param	onError	Callback for when the image couldn't load.
	 */
	public function loadImage(path:String, onLoad:Image->Void = null, onError:Void->Void = null):Image {
		var img:Image = new Image();
		createTask(function(id:Int) {
			img.addEventListener("load", function() {
				if (path.substr(path.length - 3) == "svg") {
					Browser.document.body.appendChild(img);
					img.width = img.offsetWidth;
					img.height = img.offsetHeight;
					Browser.document.body.removeChild(img);
				}
				endTask(id);
				if (onLoad != null) onLoad(img);
			});
			img.addEventListener("error", function() {
				if (onError != null) onError();
				else throw new Error("Could not load image at \"" + path + "\"");
			});
			img.src = path;
		});
		return img;
	}
	
	/**
	 * Loads text from the specified path. Returns null, so store the string you receive from the onLoad callback.
	 * @param	path	Path to the text file.
	 * @param	onLoad	Callback for when the text loads.
	 * @param	onError	Callback for when the text couldn't load.
	 */
	public function loadText(path:String, onLoad:String->Void, onError:Void->Void = null):Dynamic {
		createTask(function(id:Int) {
			var client = new XMLHttpRequest();
			client.open("GET", path);
			client.onload = function() {
				if (client.status == 200) {
					endTask(id);
					if (onLoad != null) onLoad(client.responseText);
				} else {
					if (onError != null) onError();
					else throw new Error("Could not load text at \"" + path + "\"");
				}
			};
			client.send();
		});
		return null;
	}
	
	/**
	 * Loads fonts using Google's web font loader.
	 * @param	config	The configuration for the font loader.
	 * @param	onLoad	Callback for when the fonts load.
	 * @param	onError	Callback for when the fonts couldn't load.
	 */
	public function loadFonts(config:Dynamic, onLoad:Void->Void = null, onError:Void->Void = null):Void {
		var active:Void->Void = config.active;
		var inactive:Void->Void = config.inactive;
		config.active = config.inactive = null;
		if (config.classes == null) config.classes = false;
		createTask(function(id:Int) {
			config.active = function() {
				endTask(id);
				if (active != null) active();
				if (onLoad != null) onLoad();
			};
			config.inactive = function() {
				if (inactive != null) inactive();
				if (onError != null) onError();
				if (inactive == null && onError == null) throw new Error("Could not load web fonts!");
			};
			WebFontLoader.load(config);
		});
	}
	
	/**
	 * Loads sounds for use with Howler.js.
	 * @param	options	The Howler options for the sound.
	 * @param	onLoad	Callback for when the sound loads.
	 * @param	onError	Callback for when the sound couldn't load.
	 */
	public function loadHowl(options:HowlOptions, onLoad:Howl->Void = null, onError:Void->Void = null):Howl {
		var load:Void->Void = options.onload;
		var error:Void->Void = options.onloaderror;
		options.onload = options.onloaderror = null;
		options.preload = false;
		var howl:Howl = new Howl(options);
		createTask(function(id:Int) {
			howl.on("load", function() {
				endTask(id);
				if (load != null) load();
				if (onLoad != null) onLoad(howl);
			});
			howl.on("loaderror", function() {
				if (error != null) error();
				if (onError != null) onError();
				if (error == null && onError == null) throw new Error("Could not load sound with Howler!");
			});
			howl.load();
		});
		return howl;
	}
	
}