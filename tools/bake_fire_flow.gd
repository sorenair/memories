extends SceneTree
## Converts the generated RGBA volume to a ready-to-load Texture3D resource.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var source := args[0] if not args.is_empty() else "/tmp/fire_flow.rgba"
	var data := FileAccess.get_file_as_bytes(source)
	var size := roundi(pow(float(data.size())/8.0,1.0/3.0))
	if size<2 or size*size*size*8!=data.size():
		push_error("Invalid RGBA flow volume: "+source)
		quit(1)
		return
	var layers: Array[Image] = []
	var stride := size*size*8
	for z in size:
		layers.append(Image.create_from_data(size,size,false,Image.FORMAT_RGBAH,data.slice(z*stride,(z+1)*stride)))
	var texture := ImageTexture3D.new()
	var result := texture.create(Image.FORMAT_RGBAH,size,size,size,false,layers)
	if result==OK:
		result = ResourceSaver.save(texture,"res://components/vfx/sculpted_fire/flame_flow.res",ResourceSaver.FLAG_COMPRESS)
	print("Fire flow bake: ","PASS" if result==OK else "FAIL")
	quit(0 if result==OK else 1)
