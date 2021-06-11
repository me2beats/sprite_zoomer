tool
extends EditorPlugin


#============================= node utils ======================================

static func find_node_by_class(node:Node, cls:String):
	var stack = [node]
	while stack:
		var n:Node = stack.pop_back()
		if n.get_class() == cls:return n
		stack.append_array(n.get_children())


static func find_node_by_type(node:Node, type):
	var stack = [node]
	while stack:
		var n:Node = stack.pop_back()
		if n is type:return n
		stack.append_array(n.get_children())


static func find_child_by_class(node:Node, cls:String):
	for child in node.get_children():
		if child.get_class() == cls:
			return child


static func get_nodes_by_class(node:Node, cls)->Array:
	var res:= []
	var nodes = []
	var stack = [node]
	while stack:
		var n = stack.pop_back()
		if n.get_class() ==cls:
			res.push_back(n)
		nodes.push_back(n)
		stack.append_array(n.get_children())
	return res


static func find_node_by_class_with_node_by_type(root:Node, cls:String, type)->Array:
	var result: = []
	for node in get_nodes_by_class(root, cls):
		var subnode:Node = find_node_by_type(node, type)
		if not subnode: continue
		result = [node, subnode]
		break
	return result

#===============================================================================




func _enter_tree():
	var base_control  =get_editor_interface().get_base_control()
	var sprite_frames_editor = find_node_by_class(base_control,'SpriteFramesEditor')


	var popup_and_texture_rect = find_node_by_class_with_node_by_type(
		sprite_frames_editor,
		'ConfirmationDialog',
		TextureRect
	)
	
	if not popup_and_texture_rect:
		push_error("TextureRect not found")
		return
	var popup = popup_and_texture_rect[0]
	var texture_rect = popup_and_texture_rect[1]
	

	popup.connect("about_to_show", self, "on_popup_show", [popup])
	popup.connect("hide", self, "on_popup_hide", [popup])
	popup.connect("item_rect_changed", self, 'on_popup_rect_changed', [popup, texture_rect])
	Engine.set_meta("popup", popup) 



func _exit_tree():
	var popup = Engine.get_meta("popup")
	if !popup:
		return

	popup.disconnect("about_to_show", self, "on_popup_show")
	popup.disconnect("hide", self, "on_popup_hide")
	popup.disconnect("item_rect_changed", self, 'on_popup_rect_changed')


	popup.resizable = false

	var texture_rect:TextureRect = find_node_by_class(popup, "TextureRect")

	texture_rect.remove_meta('scale')

	var box: HBoxContainer = find_child_by_class(texture_rect.get_node("../../.."),'HBoxContainer')
	if box:
		for button_name in ['scale_up', 'scale_down', 'scale_reset', 'scale_fit']:
			var button:ToolButton = box.get_node_or_null(button_name)

			if !button: continue

			box.remove_child(button)
			button.queue_free()

	Engine.remove_meta("popup") 




func on_popup_show(popup:ConfirmationDialog):
	popup.resizable = true
	var texture_rect:TextureRect = find_node_by_class(popup, "TextureRect")

#	texture_rect.set_meta('scale',1)
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	fit_scale(texture_rect)

	var box: HBoxContainer = find_child_by_class(texture_rect.get_node("../../.."),'HBoxContainer')

	if box:
		var b_scale_up:ToolButton
		b_scale_up= box.get_node_or_null("scale_up")
		if not b_scale_up:
			var base = get_editor_interface().get_base_control()
	
			b_scale_up = ToolButton.new()
			b_scale_up.icon = base.get_icon("ZoomMore", "EditorIcons")
			b_scale_up.name = "scale_up"
			b_scale_up.hint_tooltip = "Scale up"
			box.add_child(b_scale_up)
			b_scale_up.connect("pressed", self, 'scale_up', [texture_rect])



			var b_scale_down:=ToolButton.new()
			b_scale_down.icon = base.get_icon("ZoomLess", "EditorIcons")
			b_scale_down.name = "scale_down"
			b_scale_down.hint_tooltip = "Scale down"
			box.add_child(b_scale_down)
			b_scale_down.connect("pressed", self, 'scale_down', [texture_rect])


			var b_scale_reset:=ToolButton.new()
			b_scale_reset.icon = base.get_icon("ZoomReset", "EditorIcons")
			b_scale_reset.name = "scale_reset"
			b_scale_reset.hint_tooltip = "Reset scale"
			box.add_child(b_scale_reset)
			b_scale_reset.connect("pressed", self, 'reset_scale', [texture_rect])


			var b_scale_fit: = ToolButton.new()
			b_scale_fit.icon = base.get_icon("ControlAlignWide", "EditorIcons")
			b_scale_fit.name = "scale_fit"
			b_scale_fit.hint_tooltip = "Fit scale to popup window"
			box.add_child(b_scale_fit)
			b_scale_fit.connect("pressed", self, 'fit_scale', [texture_rect])


func scale_up(texture_rect:TextureRect):
	set_scale(texture_rect, texture_rect.get_meta('scale')*1.5)


func scale_down(texture_rect:TextureRect):
	set_scale(texture_rect, texture_rect.get_meta('scale')/1.5)


func reset_scale(texture_rect:TextureRect):
	set_scale(texture_rect, 1.0)


func fit_scale(texture_rect:TextureRect):
	var ratio = (texture_rect.get_parent().get_parent() as Control).rect_size/texture_rect.rect_size
	var scale = min(ratio.x-0.05, ratio.y-0.05)
	set_scale(texture_rect, scale)


func set_scale(texture_rect:TextureRect, scale:float):
	yield(get_tree(),"idle_frame")
	texture_rect.set_meta('scale', scale)

	(texture_rect.get_parent() as CenterContainer).rect_min_size = texture_rect.rect_size*scale

	yield(get_tree(),"idle_frame")
	texture_rect.rect_pivot_offset = texture_rect.rect_size/2

	texture_rect.rect_scale = Vector2(scale,scale)



func on_popup_rect_changed(popup:ConfirmationDialog, texture_rect:TextureRect):
	yield(get_tree(),"idle_frame")
	
	if not texture_rect.has_meta('scale'): return
	(texture_rect.get_parent() as CenterContainer).rect_min_size = texture_rect.rect_size*texture_rect.get_meta('scale')

	yield(get_tree(),"idle_frame")
	
	
	texture_rect.rect_scale = Vector2.ONE*texture_rect.get_meta('scale')



func on_popup_hide(popup:ConfirmationDialog):
	var texture_rect:TextureRect = find_node_by_class(popup, "TextureRect")
	reset_scale(texture_rect)


