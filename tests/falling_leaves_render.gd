extends SceneTree
func _initialize():
 call_deferred("run")
func snapshot():
 await RenderingServer.frame_post_draw
 var img=root.get_texture().get_image()
 img.resize(600,600)
 return img
func changes(a,b):
 var x=a.get_data()
 var y=b.get_data()
 var n=0
 for i in range(x.size()):
  if absi(int(x[i])-int(y[i]))>3:n+=1
 return n
func run():
 root.content_scale_size=Vector2i(900,900)
 var scene=Node3D.new()
 root.add_child(scene)
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(0.94,0.935,0.89)
 scene.add_child(env)
 var tree=load("res://components/foliage/painterly_tree.tscn").instantiate()
 tree.falling_leaf_count=32
 tree.falling_leaf_rate=4.0
 tree.wind_strength=0.0
 scene.add_child(tree)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=6.5
 scene.add_child(camera)
 camera.position=Vector3(7,5,7)
 camera.look_at(Vector3(0,1.9,0))
 await create_timer(.4).timeout
 var a=await snapshot()
 await create_timer(.6).timeout
 var b=await snapshot()
 root.get_texture().get_image().save_png("res://docs/falling-leaves.png")
 tree.falling_leaf_rate=0.0
 await create_timer(.1).timeout
 var c=await snapshot()
 await create_timer(.4).timeout
 var d=await snapshot()
 print("Falling leaf render | motion: ",changes(a,b)," | zero rate: ",changes(c,d))
 quit(0 if changes(a,b)>100 and changes(c,d)==0 else 1)
