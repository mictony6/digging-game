@tool
extends Node3D
@export var material: Material
@export var source_mesh_instance: MeshInstance3D
@export var chunk_size: float = 32.0
@export var split_now: bool = false:
    set(value):
        if value:
            split_terrain()
            

func split_terrain():
    if not source_mesh_instance or not source_mesh_instance.mesh:
        push_error("No source mesh assigned")
        return
    
    var mdt = MeshDataTool.new()
    mdt.create_from_surface(source_mesh_instance.mesh, 0)
    
    # Group faces by chunk
    var chunk_faces = {}
    
    for face_idx in mdt.get_face_count():
        var center = Vector3.ZERO
        for i in 3:
            center += mdt.get_vertex(mdt.get_face_vertex(face_idx, i))
        center /= 3.0
        
        var key = Vector2i(floor(center.x / chunk_size), floor(center.z / chunk_size))
        if not chunk_faces.has(key):
            chunk_faces[key] = []
        chunk_faces[key].append(face_idx)
    
    # Create chunk meshes
    for key in chunk_faces:
        var st = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        
        for face_idx in chunk_faces[key]:
            for i in 3:
                var vert_idx = mdt.get_face_vertex(face_idx, i)
                st.set_normal(mdt.get_vertex_normal(vert_idx))
                st.set_uv(mdt.get_vertex_uv(vert_idx))
                st.add_vertex(mdt.get_vertex(vert_idx))
        
        st.generate_tangents()
        st.index()
        
        var chunk = MeshInstance3D.new()
        chunk.mesh = st.commit()
        chunk.name = "Chunk_%d_%d" % [key.x, key.y]
        chunk.material_override = source_mesh_instance.material_override
        add_child(chunk)
        chunk.owner = get_tree().edited_scene_root # So it saves in editor
        chunk.material_override = material
    
    print("Created %d chunks" % chunk_faces.size())