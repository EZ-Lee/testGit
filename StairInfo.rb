class StairInfo # 楼梯通用功能
	attr_reader :stairGroup, :stairTrans, :treadFaces, :treadFacesEdgesArray, :treadFacesPtsArray, :rakingRiserFaces

	def initialize(stair_group, stair_group_tr)
		@stairGroup = stair_group                 # 传入楼梯群组
		@stairTrans = stair_group_tr              # 楼梯组的矩阵
		@treadFaces = []                        # 楼梯踏面
		@treadFacesEdgesArray = []              # 环绕踏面 4 组线，左→下→右→上，[[[edge1, edge2], [edge3], [edge4, edge5], [edge6]], [[edge1, edge2], [edge3], [edge4, edge5], [edge6]]...]
		@treadFacesPtsArray = []                # 环绕踏面 4 组线的点，左→下→右→上，[[[pt1, pt2], [pt3], [pt4, pt5], [pt6]], [[pt1, pt2], [pt3], [pt4, pt5], [pt6]]...]
		@rakingRiserFaces = []                  # 楼梯踢面

		model = Sketchup.active_model
		model.start_operation "", true
		main()
		model.commit_operation
	end

	def main
		# 取得楼梯踏面（由低至高）
		@treadFaces = @stairGroup.entities.find_all{|e|
			e.is_a?(Sketchup::Face) && (@stairTrans * e.normal).angle_between(Z_AXIS) < 15.degrees
		}
		@treadFaces.sort_by!{|e|
			(@stairTrans * e.bounds.center).z
		}
		#获取楼梯踢面
		@treadFaces.each_with_index{|face, index|
			faceArr = []
			face.outer_loop.edges.each{|e|
				if e.faces.length > 1
					e.faces.each{|f| 
						if (@stairTrans * f.bounds.center).z < (@stairTrans * face.bounds.center).z
							faceArr.push(f)
						end
					}
				end
			}
			@rakingRiserFaces.push(faceArr)
		}	
		#获取楼面踏面4组线
		@treadFaces.each_with_index{|face, index|
			com_edgeuse = []
			face.outer_loop.edgeuses.each{|e| com_edgeuse.push(e) if e.edge.soft?}
			down_edgeuse = []
			@rakingRiserFaces[index].each{|face1|
				com_edgeuse.find{|e| down_edgeuse.push(e) if e.edge.used_by?face1}
			}
			up_edgeuse = com_edgeuse - down_edgeuse
			#down_edges数组
			sortDown_edgeuse = sortByEdgeuse([down_edgeuse[0]], down_edgeuse)
			#up_edges数组
			sortUp_edgeuse = sortByEdgeuse([up_edgeuse[0]], up_edgeuse)
			#rigth数组
			sortRight_edgeuse = []
			rst_edgeuse = sortDown_edgeuse[-1].next
			while rst_edgeuse != sortUp_edgeuse[0]
				sortRight_edgeuse.push(rst_edgeuse)
				rst_edgeuse = rst_edgeuse.next
			end 
			#left数组
			sortLeft_edgeuse = []
			lst_edgeuse = sortUp_edgeuse[-1].next
			while lst_edgeuse != sortDown_edgeuse[0]
				sortLeft_edgeuse.push(lst_edgeuse)
				lst_edgeuse = lst_edgeuse.next 
			end
			sortLeft_edgeuse.map!{|edgeuse| edgeuse.edge}
			sortDown_edgeuse.map!{|edgeuse| edgeuse.edge}
			sortRight_edgeuse.map!{|edgeuse| edgeuse.edge}
			sortUp_edgeuse.map!{|edgeuse| edgeuse.edge}
			edgesArray = [sortLeft_edgeuse,sortDown_edgeuse,sortRight_edgeuse,sortUp_edgeuse]
			@treadFacesEdgesArray.push(edgesArray)
		}
		# 获得踏面路径顶点并排列
		@treadFacesPtsArray = []
		@treadFacesEdgesArray.each_with_index{|edgesArr, index|
			tempPts = []
			edgesArr.each{|edges|
				_pts = sortEdgesPtsByFace(edges, @treadFaces[index])
				tempPts << _pts.map{|pt| pt.transform(@stairTrans)}
			}
			@treadFacesPtsArray << tempPts
		}
	end

	def sortByEdgeuse(sort_edgeuse, edgeuse)
		use_next = nextEdgeuse(edgeuse, edgeuse[0].next)    #下一条edgeuse
		while use_next
			sort_edgeuse.push(use_next) 
			use_next = nextEdgeuse(edgeuse, use_next.next)
		end
		use_pre = nextEdgeuse(edgeuse, edgeuse[0].previous) #上一条edgeuse
		while use_pre
			sort_edgeuse.unshift(use_pre)
			use_pre = nextEdgeuse(edgeuse, use_pre.previous)
		end
		return sort_edgeuse
	end

	def nextEdgeuse(edgeuses, edgeuse) #求取相邻edgeuse
		if edgeuses.include? edgeuse
			return edgeuse
		end
		return nil
	end

	# 对已选择的属于一个面的连续的线，进行排序
	def sortEdgesPtsByFace(edges, face)
		index1 = face.outer_loop.edges.index(edges[0])
		index2 = face.outer_loop.edges.index(edges[-1])
		faceVertices = face.outer_loop.vertices
		if index2 < index1
			vts = faceVertices[index1..-1] + faceVertices[0..(index2 + 1)]
		else
			if index2 == faceVertices.length - 1
				vts = faceVertices[index1..index2] + [faceVertices[0]]
			else
				vts = faceVertices[index1..(index2 + 1)]
			end
		end
		return vts.map{|v| v.position}
	end
	
end
model = Sketchup.active_model
ents = model.active_entities
sel = model.selection

group = sel.first
stair = StairInfo.new(group, group.transformation)
# command = [:stairGroup, :stairTrans, :treadFaces, :treadFacesEdgesArray, :treadFacesPtsArray, :rakingRiserFaces]
# command.each {|method_name|
	# puts "#{method_name} -> #{stair.send(method_name)}"
# }

sel.clear
count = 0

timer = UI.start_timer(0.25, true) {
	if !(count < stair.treadFacesEdgesArray.length * 4 - 1)
		UI.stop_timer(timer)
	end
	i = count / 4
	j = count % 4
	edges = stair.treadFacesEdgesArray[i][j]
	count += 1
	sel.clear
	sel.add(edges)
}
