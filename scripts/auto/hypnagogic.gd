extends Node

func _ready() -> void:
	loadConfigFile()

#region // 󱁤 UTIL.

# https://kidscancode.org/godot_recipes/3.x/3d/3d_align_surface/index.html
## Taken from [url=https://kidscancode.org/godot_recipes/3.x/3d/3d_align_surface/index.html]kidscancode.org[/url].[br]
## Aligns Y+ from [param xform] to [param normal].[br]
## | [param xform]    transform like [member Node3D.global_transform].[br]
## | [param normal]    the normal vector to align [param xform]'s Y+ to.[br]
## [b]returns.[/b]    [param xform] with Y+ pointing towards [param normal].
static func alignWithY(xform: Transform3D, normal: Vector3) -> Transform3D:
	xform.basis.y = normal
	xform.basis.x = -xform.basis.z.cross(normal)
	xform.basis = xform.basis.orthonormalized()
	return xform

#endregion 󱁤 UTIL.

#region //  CONFIG.

const CONFIG_FILEPATH : String = "user://.config"
static var config : ConfigFile = ConfigFile.new() ## Configuration file that houses player preferences.

## Attempts to load a config file.[br]
## [b]returns.[/b]    [code]true[/code] if file loaded from disk, [code]false[/code] if new file created.
static func loadConfigFile() -> bool:
	var err = config.load(CONFIG_FILEPATH)
	
	if err != OK:
		print("error: ", str(err))
		match err:
			ERR_FILE_NOT_FOUND:
				pass
			ERR_FILE_BAD_DRIVE:
				pass
			ERR_FILE_BAD_PATH:
				pass
			ERR_FILE_NO_PERMISSION:
				pass
			ERR_FILE_ALREADY_IN_USE:
				pass
			ERR_FILE_CANT_OPEN:
				pass
			ERR_FILE_CANT_WRITE:
				pass
			ERR_FILE_CANT_READ:
				pass
			ERR_FILE_UNRECOGNIZED:
				pass
			ERR_FILE_CORRUPT:
				pass
			ERR_FILE_MISSING_DEPENDENCIES:
				pass
			ERR_FILE_EOF:
				pass
		
		return false
	
	print("a ok")
	
	return true

#endregion  CONFIG.

#region //  ERROR.

## Show error to player. Avoid using, just pulls up generic error prompt.[br]
## | [param error]    what should be shown in the prompt.[br]
## | [param breaking]    dictates if game should close after.
static func showError(error: String, breaking: bool = false) -> void:
	# TODO : prompt error ui.
	pass

#endregion  ERROR.
