model = Sketchup.active_model
ent = model.active_entities
sel = model.selection

face = sel.first
face.loops.each{|loop|
	loop.edgeuses.each{|edgeuse|
		# 当前loop中：[上一个edgeuse, , 下一个edgeuse]
		# p [edgeuse.previous.edge, edgeuse.edge, edgeuse.next.edge]

		# p edgeuse.edge
		
		# p edgeuse.face
		
		# p edgeuse.loop
		
		# p [edgeuse.start_vertex_normal, edgeuse.end_vertex_normal]
		
		# if edgeuse.reversed? # 判断边线方向是不是反了
			# p [edgeuse.edge.end.position, edgeuse.edge.start.position]
		# else
			# p [edgeuse.edge.start.position, edgeuse.edge.end.position]
		# end

		# p [edgeuse, edgeuse.partners]

		# 如果该边线属于多个面，那么partners的个数 = 面数 - 1；如果属于单个面，那么partners == []
		sel.clear
		edgeuse.partners.each{|_edgeuse|
			sel.add _edgeuse.loop.face
			UI.messagebox ''
		}
	}
}
puts