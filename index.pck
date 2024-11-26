GDPC                �                                                                         `   res://.godot/exported/133200997/export-9b9c6bdce023f71320d3fd54a9d670ee-Polyline3DMaterial.res  �      �      Z���h�ʲ&�SӶ    ,   res://.godot/global_script_class_cache.cfg  `�      =      ����K/����w+U��    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex�            ：Qt�E�cO���       res://.godot/uid_cache.bin  ��      �       �'�m \�K��WS ��       res://Demo/DemoScene.tscn          �      U�c�gL�k{���U       res://Demo/demo_animation.gd �      �       �yA�yzY�p�:�P�    $   res://Demo/demo_camera_animation.gd �      -      j��}d�6�u�
k%��    ,   res://addons/ShapesAndLines/Polyline3D.gd           �      �p��W<ת�ZI'��W    0   res://addons/ShapesAndLines/Polyline3D.gdshader �      Y      YPc;#Go#��$SW{    <   res://addons/ShapesAndLines/Polyline3DMaterial.tres.remap   �      o       �r�B _�������    ,   res://addons/ShapesAndLines/VectorShape3D.gd�            �V+�Jx�_�M��� Ձ       res://icon.svg  ��      �      �W|��/�\�pF[       res://icon.svg.import   0�      �       ���'���RoG!%d�Y       res://project.binary �      �      �b�wدhA�=�#L��        @tool

class_name Polyline3D
extends MeshInstance3D

@export_range(0.0, 100.0) var width: float = 3.0:
	set(value):
		width = value
		regenerateMesh();

@export var color: Color:
	set(value):
		color = value
		regenerateMesh()

@export var points: PackedVector3Array = [Vector3(0, 0, 0), Vector3(20, 20, 20)]:
	set(value):
		points = value
		regenerateMesh()

@export var debug: bool = false:
	set(value):
		debug = value
		regenerateMesh()

func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	mesh = ArrayMesh.new()
	regenerateMesh()

func regenerateMesh() -> void:
	if not Engine.is_editor_hint():
		return

	var numPoints := points.size()
	if numPoints <= 1:
		return

	# First, populate the vertices
	var vertices: PackedVector3Array = []
	vertices.resize((numPoints-1) * 4)
	for i in numPoints-1:
		vertices[i*4] = points[i]
		vertices[i*4 + 1] = points[i] + Vector3(0.001,0.001,0.001)
		vertices[i*4 + 2] = points[i+1]
		vertices[i*4 + 3] = points[i+1] + Vector3(0.001,0.001,0.001)

	# Populate the colors
	var colors: PackedColorArray = []
	colors.resize((numPoints-1) * 4);
	for i in numPoints-1:
		colors[i*4] = color
		colors[i*4 + 1] = color
		colors[i*4 + 2] = color
		colors[i*4 + 3] = color

	# Populate the normals
	var normals: PackedVector3Array = []
	normals.resize((numPoints-1) * 4)
	for i in numPoints-1:
		normals[i*4] = points[i+1] - points[i]
		normals[i*4 + 1] = points[i+1] - points[i]
		normals[i*4 + 2] = normals[i*4]
		normals[i*4 + 3] = normals[i*4 + 1]

	# Populate the UVs
	var uvs: PackedVector2Array = []
	uvs.resize((numPoints-1) * 4)
	for i in numPoints-1:
		uvs[i*4] = Vector2(0, 1)
		uvs[i*4 + 1] = Vector2(1, 1)
		uvs[i*4 + 2] = Vector2(0, 0)
		uvs[i*4 + 3] = Vector2(1, 0)

	# Populate the indices
	var indices: PackedInt32Array = []
	indices.resize((numPoints-1) * 6 + (numPoints-2)*6)
	for i in (numPoints - 1) + (numPoints - 2):
		var startIndex := i * 6

		indices[startIndex] = i*2
		indices[startIndex + 1] = i*2 + 1
		indices[startIndex + 2] = i*2 + 2

		indices[startIndex + 3] = i*2 + 2
		indices[startIndex + 4] = i*2 + 1
		indices[startIndex + 5] = i*2 + 3

	# Allow for mesh to be updated without fully regenerating each time
	if not is_instance_valid(mesh):
		mesh = ArrayMesh.new()

	# Generate the new surface
	var newSurfaceArray: Array = []
	newSurfaceArray.resize(Mesh.ARRAY_MAX)
	newSurfaceArray[Mesh.ARRAY_VERTEX] = vertices
	newSurfaceArray[Mesh.ARRAY_NORMAL] = normals
	newSurfaceArray[Mesh.ARRAY_TEX_UV] = uvs
	newSurfaceArray[Mesh.ARRAY_INDEX] = indices
	newSurfaceArray[Mesh.ARRAY_COLOR] = colors

	var material: Material = preload("res://addons/ShapesAndLines/Polyline3DMaterial.tres").duplicate(true)
	material.set_shader_parameter("width", width)
	material.set_shader_parameter("debug", debug)
	var arrayMesh := mesh as ArrayMesh
	arrayMesh.clear_surfaces()
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, newSurfaceArray)
	self.material_override = material;      shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}       RSRC                    ShaderMaterial            ��������                                                  resource_local_to_scene    resource_name    render_priority 
   next_pass    shader    shader_parameter/width    shader_parameter/debug    script       Shader 0   res://addons/ShapesAndLines/Polyline3D.gdshader ��������      local://ShaderMaterial_5vsjq �         ShaderMaterial                                                        A                RSRC              @tool

class_name VectorShape3D
extends Polyline3D

@export_range(3, 24) var sides: int = 4:
	set(value):
		sides = value
		regenerateShape()

@export var radius: float = 10.0:
	set(value):
		radius = value
		regenerateShape()

func regenerateShape() -> void:
	var newPoints: PackedVector3Array = [];
	for i in range(sides+2): # +2 to close the shape as a workaround for now
		var angle := (i + 0.5) * 2 * PI / sides
		newPoints.append(Vector3(sin(angle) * radius, 0.0, cos(angle) * radius))

	points = newPoints;               [gd_scene load_steps=38 format=4 uid="uid://cc0aq386efdee"]

[ext_resource type="Script" path="res://addons/ShapesAndLines/VectorShape3D.gd" id="4_1bbda"]
[ext_resource type="Script" path="res://Demo/demo_camera_animation.gd" id="4_l381x"]
[ext_resource type="Script" path="res://addons/ShapesAndLines/Polyline3D.gd" id="4_wvuin"]
[ext_resource type="Script" path="res://Demo/demo_animation.gd" id="5_wyyr3"]

[sub_resource type="Shader" id="Shader_td63a"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_a7vdh"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_td63a")
shader_parameter/width = 4.638
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_2nk65"]
_surfaces = [{
"aabb": AABB(-44.5689, 0, -44.5689, 89.1388, 0.001, 89.1388),
"attribute_data": PackedByteArray("vLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 54,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 20,
"vertex_data": PackedByteArray("jkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjLClEcyQm8SgzqIRTLCjkYyQgAAAACORjLClEcyQm8SgzqIRTLCjkYywgAAAACORjLCiEUywm8SgzqIRTLCjkYywgAAAACORjLCiEUywm8SgzqIRTLCjkYywgAAAACORjJCiEUywm8SgzqURzJCjkYywgAAAACORjJCiEUywm8SgzqURzJCjkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjLClEcyQm8SgzqIRTLC//////9/AID//////38AgP//////fwCA//////9/AIAAAP9//3//vwAA/3//f/+/AAD/f/9//78AAP9//3//v/9//3//fwCA/3//f/9/AID/f/9//38AgP9//3//fwCA////f/9//7////9//3//v////3//f/+/////f/9//7///////38AgP//////fwCA//////9/AID//////38AgA==")
}]

[sub_resource type="Shader" id="Shader_qv4de"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_o6cm2"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_qv4de")
shader_parameter/width = 4.638
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_wgbw5"]
_surfaces = [{
"aabb": AABB(-43.4977, 0, -43.4977, 86.9964, 0.001, 86.9964),
"attribute_data": PackedByteArray("vLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 54,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 20,
"vertex_data": PackedByteArray("pf0tQgAAAACl/S1Cq/4tQm8Sgzqr/i1Cpf0tQgAAAACl/S3Cq/4tQm8Sgzqf/C3Cpf0tQgAAAACl/S3Cq/4tQm8Sgzqf/C3Cpf0twgAAAACl/S3Cn/wtwm8Sgzqf/C3Cpf0twgAAAACl/S3Cn/wtwm8Sgzqf/C3Cpf0twgAAAACl/S1Cn/wtwm8Sgzqr/i1Cpf0twgAAAACl/S1Cn/wtwm8Sgzqr/i1Cpf0tQgAAAACl/S1Cq/4tQm8Sgzqr/i1Cpf0tQgAAAACl/S1Cq/4tQm8Sgzqr/i1Cpf0tQgAAAACl/S3Cq/4tQm8Sgzqf/C3C//////9/AID//////38AgP//////fwCA//////9/AIAAAP9//3//vwAA/3//f/+/AAD/f/9//78AAP9//3//v/9//3//fwCA/3//f/9/AID/f/9//38AgP9//3//fwCA////f/9//7////9//3//v////3//f/+/////f/9//7///////38AgP//////fwCA//////9/AID//////38AgA==")
}]

[sub_resource type="Shader" id="Shader_vdy5b"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ghbnx"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_vdy5b")
shader_parameter/width = 4.638
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_dp2ld"]
_surfaces = [{
"aabb": AABB(-44.5689, 0, -44.5689, 89.1388, 0.001, 89.1388),
"attribute_data": PackedByteArray("vLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAAvLy8/wAAAAAAAIA/vLy8/wAAgD8AAIA/vLy8/wAAAAAAAAAAvLy8/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 54,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 20,
"vertex_data": PackedByteArray("jkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjLClEcyQm8SgzqIRTLCjkYyQgAAAACORjLClEcyQm8SgzqIRTLCjkYywgAAAACORjLCiEUywm8SgzqIRTLCjkYywgAAAACORjLCiEUywm8SgzqIRTLCjkYywgAAAACORjJCiEUywm8SgzqURzJCjkYywgAAAACORjJCiEUywm8SgzqURzJCjkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjJClEcyQm8SgzqURzJCjkYyQgAAAACORjLClEcyQm8SgzqIRTLC//////9/AID//////38AgP//////fwCA//////9/AIAAAP9//3//vwAA/3//f/+/AAD/f/9//78AAP9//3//v/9//3//fwCA/3//f/9/AID/f/9//38AgP9//3//fwCA////f/9//7////9//3//v////3//f/+/////f/9//7///////38AgP//////fwCA//////9/AID//////38AgA==")
}]

[sub_resource type="Shader" id="Shader_kq58b"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_73ws2"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_kq58b")
shader_parameter/width = 4.0
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_sok3m"]
_surfaces = [{
"aabb": AABB(0, 0, 0, 400.001, 100.001, 0.001),
"attribute_data": PackedByteArray("uu8A/wAAAAAAAIA/uu8A/wAAgD8AAIA/uu8A/wAAAAAAAAAAuu8A/wAAgD8AAAAAuu8A/wAAAAAAAIA/uu8A/wAAgD8AAIA/uu8A/wAAAAAAAAAAuu8A/wAAgD8AAAAAuu8A/wAAAAAAAIA/uu8A/wAAgD8AAIA/uu8A/wAAAAAAAAAAuu8A/wAAgD8AAAAAuu8A/wAAAAAAAIA/uu8A/wAAgD8AAIA/uu8A/wAAAAAAAAAAuu8A/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 42,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8A"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 16,
"vertex_data": PackedByteArray("AAAAAAAAyEIAAAAAbxKDOoMAyEJvEoM6AADIQgAAAAAAAAAAgwDIQm8SgzpvEoM6AADIQgAAAAAAAAAAgwDIQm8SgzpvEoM6AABIQwAAAAAAAAAAQgBIQ28SgzpvEoM6AABIQwAAAAAAAAAAQgBIQ28SgzpvEoM6AACWQwAAyEIAAAAAIQCWQ4MAyEJvEoM6AACWQwAAyEIAAAAAIQCWQ4MAyEJvEoM6AADIQwAAAAAAAAAAIQDIQ28SgzpvEoM6/7//P1RVqar/v/8/VFWpqv+//z9UVamq/7//P1RVqar///9//3//v////3//f/+/////f/9//7////9//3//v/+//79UVVTV/7//v1RVVNX/v/+/VFVU1f+//79UVVTV/7//P1RVqar/v/8/VFWpqv+//z9UVamq/7//P1RVqao=")
}]

[sub_resource type="Shader" id="Shader_1hrmo"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_6a8k2"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_1hrmo")
shader_parameter/width = 19.538
shader_parameter/debug = true

[sub_resource type="ArrayMesh" id="ArrayMesh_iwdyf"]
_surfaces = [{
"aabb": AABB(0, 0, 0, 400.001, 100.001, 0.001),
"attribute_data": PackedByteArray("fn5+/wAAAAAAAIA/fn5+/wAAgD8AAIA/fn5+/wAAAAAAAAAAfn5+/wAAgD8AAAAAfn5+/wAAAAAAAIA/fn5+/wAAgD8AAIA/fn5+/wAAAAAAAAAAfn5+/wAAgD8AAAAAfn5+/wAAAAAAAIA/fn5+/wAAgD8AAIA/fn5+/wAAAAAAAAAAfn5+/wAAgD8AAAAAfn5+/wAAAAAAAIA/fn5+/wAAgD8AAIA/fn5+/wAAAAAAAAAAfn5+/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 42,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8A"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 16,
"vertex_data": PackedByteArray("AAAAAAAAyEIAAAAAbxKDOoMAyEJvEoM6AADIQgAAAAAAAAAAgwDIQm8SgzpvEoM6AADIQgAAAAAAAAAAgwDIQm8SgzpvEoM6AABIQwAAAAAAAAAAQgBIQ28SgzpvEoM6AABIQwAAAAAAAAAAQgBIQ28SgzpvEoM6AACWQwAAyEIAAAAAIQCWQ4MAyEJvEoM6AACWQwAAyEIAAAAAIQCWQ4MAyEJvEoM6AADIQwAAAAAAAAAAIQDIQ28SgzpvEoM6/7//P1RVqar/v/8/VFWpqv+//z9UVamq/7//P1RVqar///9//3//v////3//f/+/////f/9//7////9//3//v/+//79UVVTV/7//v1RVVNX/v/+/VFVU1f+//79UVVTV/7//P1RVqar/v/8/VFWpqv+//z9UVamq/7//P1RVqao=")
}]

[sub_resource type="Shader" id="Shader_tuyhs"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_vt35g"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_tuyhs")
shader_parameter/width = 3.0
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_a7423"]
_surfaces = [{
"aabb": AABB(-38.75, 0, -33.5585, 77.501, 0.001, 67.118),
"attribute_data": PackedByteArray("AOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 78,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMAEgATABQAFAATABUAFAAVABYAFgAVABcAFgAXABgAGAAXABkAGAAZABoAGgAZABsA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 28,
"vertex_data": PackedByteArray("AACbQQAAAADnOwZCDAKbQW8SgzrtPAZCAAAbQgAAAAAJ+ConBgEbQm8SgzpvEoM6AAAbQgAAAAAJ+ConBgEbQm8SgzpvEoM6AACbQQAAAADnOwbCDAKbQW8SgzrhOgbCAACbQQAAAADnOwbCDAKbQW8SgzrhOgbCAACbwQAAAADnOwbC9P2awW8SgzrhOgbCAACbwQAAAADnOwbC9P2awW8SgzrhOgbCAAAbwgAAAAATOgCo+v4awm8SgzpvEoM6AAAbwgAAAAATOgCo+v4awm8SgzpvEoM6AACbwQAAAADnOwZC9P2awW8SgzrtPAZCAACbwQAAAADnOwZC9P2awW8SgzrtPAZCAACbQQAAAADnOwZCDAKbQW8SgzrtPAZCAACbQQAAAADnOwZCDAKbQW8SgzrtPAZCAAAbQgAAAACObVApBgEbQm8SgzpvEoM6//8l0aymgJ7//yXRrKaAnv//JdGspoCe//8l0aymgJ4AACXRUlmAngAAJdFSWYCeAAAl0VJZgJ4AACXRUlmAngAA/3//f/+/AAD/f/9//78AAP9//3//vwAA/3//f/+/JVH/f6ymgJ4lUf9/rKaAniVR/3+spoCeJVH/f6ymgJ7Zrv9/UlmAntmu/39SWYCe2a7/f1JZgJ7Zrv9/UlmAnv///3//f/+/////f/9//7////9//3//v////3//f/+///8l0aymgJ7//yXRrKaAnv//JdGspoCe//8l0aymgJ4=")
}]

[sub_resource type="Shader" id="Shader_bktmr"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_7xy0l"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_bktmr")
shader_parameter/width = 2.0
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_mjlf6"]
_surfaces = [{
"aabb": AABB(-21.4558, 0, -24.775, 42.9126, 0.001, 49.551),
"attribute_data": PackedByteArray("AOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAAAOHt/wAAAAAAAIA/AOHt/wAAgD8AAIA/AOHt/wAAAAAAAAAAAOHt/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 78,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMAEgATABQAFAATABUAFAAVABYAFgAVABcAFgAXABgAGAAXABkAGAAZABoAGgAZABsA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 28,
"vertex_data": PackedByteArray("AAAAAAAAAAAzM8ZBbxKDOm8Sgzo/NcZBeqWrQQAAAAAzM0ZBhqerQW8SgzpMN0ZBeqWrQQAAAAAzM0ZBhqerQW8SgzpMN0ZBeqWrQQAAAAAzM0bBhqerQW8SgzoaL0bBeqWrQQAAAAAzM0bBhqerQW8SgzoaL0bBr55aJwAAAAAzM8bBbxKDOm8SgzonMcbBr55aJwAAAAAzM8bBbxKDOm8SgzonMcbBeqWrwQAAAAAzM0bBbqOrwW8SgzoaL0bBeqWrwQAAAAAzM0bBbqOrwW8SgzoaL0bBeqWrwQAAAAAzM0ZBbqOrwW8SgzpMN0ZBeqWrwQAAAAAzM0ZBbqOrwW8SgzpMN0ZBr57apwAAAAAzM8ZBbxKDOm8Sgzo/NcZBr57apwAAAAAzM8ZBbxKDOm8Sgzo/NcZBeqWrQQAAAAAzM0ZBhqerQW8SgzpMN0ZB///Zrqym1LT//9murKbUtP//2a6sptS0///Zrqym1LT//////38AgP//////fwCA//////9/AID//////38AgAAA2a5SWdS0AADZrlJZ1LQAANmuUlnUtAAA2a5SWdS02S7/f6ym1LTZLv9/rKbUtNku/3+sptS02S7/f6ym1LT/f/9//38AgP9//3//fwCA/3//f/9/AID/f/9//38AgCXR/39SWdS0JdH/f1JZ1LQl0f9/UlnUtCXR/39SWdS0///Zrqym1LT//9murKbUtP//2a6sptS0///Zrqym1LQ=")
}]

[sub_resource type="Shader" id="Shader_njavb"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_x6e0h"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_njavb")
shader_parameter/width = 1.0
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_sumb6"]
_surfaces = [{
"aabb": AABB(-29.0692, 0, -29.0692, 58.1394, 0.001, 58.1394),
"attribute_data": PackedByteArray("7QAE/wAAAAAAAIA/7QAE/wAAgD8AAIA/7QAE/wAAAAAAAAAA7QAE/wAAgD8AAAAA7QAE/wAAAAAAAIA/7QAE/wAAgD8AAIA/7QAE/wAAAAAAAAAA7QAE/wAAgD8AAAAA7QAE/wAAAAAAAIA/7QAE/wAAgD8AAIA/7QAE/wAAAAAAAAAA7QAE/wAAgD8AAAAA7QAE/wAAAAAAAIA/7QAE/wAAgD8AAIA/7QAE/wAAAAAAAAAA7QAE/wAAgD8AAAAA7QAE/wAAAAAAAIA/7QAE/wAAgD8AAIA/7QAE/wAAAAAAAAAA7QAE/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 54,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 20,
"vertex_data": PackedByteArray("uY3oQQAAAAC5jehBxY/oQW8SgzrFj+hBuY3oQQAAAAC5jejBxY/oQW8Sgzqti+jBuY3oQQAAAAC5jejBxY/oQW8Sgzqti+jBuY3owQAAAAC5jejBrYvowW8Sgzqti+jBuY3owQAAAAC5jejBrYvowW8Sgzqti+jBuY3owQAAAAC5jehBrYvowW8SgzrFj+hBuY3owQAAAAC5jehBrYvowW8SgzrFj+hBuY3oQQAAAAC5jehBxY/oQW8SgzrFj+hBuY3oQQAAAAC5jehBxY/oQW8SgzrFj+hBuY3oQQAAAAC5jejBxY/oQW8Sgzqti+jB//////9/AID//////38AgP//////fwCA//////9/AIAAAP9//3//vwAA/3//f/+/AAD/f/9//78AAP9//3//v/9//3//fwCA/3//f/9/AID/f/9//38AgP9//3//fwCA////f/9//7////9//3//v////3//f/+/////f/9//7///////38AgP//////fwCA//////9/AID//////38AgA==")
}]

[sub_resource type="Shader" id="Shader_47l4h"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_54md8"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_47l4h")
shader_parameter/width = 1.0
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_ovykq"]
_surfaces = [{
"aabb": AABB(-15.4467, 0, -15.4467, 30.8944, 0.001, 30.8944),
"attribute_data": PackedByteArray("/dHU/wAAAAAAAIA//dHU/wAAgD8AAIA//dHU/wAAAAAAAAAA/dHU/wAAgD8AAAAA/dHU/wAAAAAAAIA//dHU/wAAgD8AAIA//dHU/wAAAAAAAAAA/dHU/wAAgD8AAAAA/dHU/wAAAAAAAIA//dHU/wAAgD8AAIA//dHU/wAAAAAAAAAA/dHU/wAAgD8AAAAA/dHU/wAAAAAAAIA//dHU/wAAgD8AAIA//dHU/wAAAAAAAAAA/dHU/wAAgD8AAAAA/dHU/wAAAAAAAIA//dHU/wAAgD8AAIA//dHU/wAAAAAAAAAA/dHU/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 54,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8ADgAPABAAEAAPABEAEAARABIAEgARABMA"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 20,
"vertex_data": PackedByteArray("ryV3QQAAAACvJXdByCl3QW8SgzrIKXdBryV3QQAAAACvJXfByCl3QW8SgzqWIXfBryV3QQAAAACvJXfByCl3QW8SgzqWIXfBryV3wQAAAACvJXfBliF3wW8SgzqWIXfBryV3wQAAAACvJXfBliF3wW8SgzqWIXfBryV3wQAAAACvJXdBliF3wW8SgzrIKXdBryV3wQAAAACvJXdBliF3wW8SgzrIKXdBryV3QQAAAACvJXdByCl3QW8SgzrIKXdBryV3QQAAAACvJXdByCl3QW8SgzrIKXdBryV3QQAAAACvJXfByCl3QW8SgzqWIXfB//////9/AID//////38AgP//////fwCA//////9/AIAAAP9//3//vwAA/3//f/+/AAD/f/9//78AAP9//3//v/9//3//fwCA/3//f/9/AID/f/9//38AgP9//3//fwCA////f/9//7////9//3//v////3//f/+/////f/9//7///////38AgP//////fwCA//////9/AID//////38AgA==")
}]

[sub_resource type="Shader" id="Shader_ysw6m"]
code = "shader_type spatial;
render_mode cull_front, unshaded;

uniform float width = 10.0;
uniform bool debug = false;

vec2 rotate90Degrees(vec2 v) {
    return vec2(-v.y, v.x);
}

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec4 position_with_offset = PROJECTION_MATRIX * (MODELVIEW_MATRIX * (vec4(VERTEX, 1.0) + vec4((2.*UV.x-.5) * NORMAL/100.0, 0.)));
	vec2 offset_direction = position_with_offset.xy / position_with_offset.w - clip_position.xy / clip_position.w;
	
	vec2 offset = (rotate90Degrees(normalize(offset_direction * VIEWPORT_SIZE))) / VIEWPORT_SIZE * clip_position.w * width * 2.0;
	POSITION = clip_position + vec4(offset, 0., 0.);
}

void fragment() {
	float xLengthOnScreen = length(vec2(1.0/dFdx(UV).x, 1.0/dFdy(UV).x));
	
	float uvXStretch = length(vec2(dFdx(UV).x, dFdy(UV).x));
	float uvYStretch = length(vec2(dFdx(UV).y, dFdy(UV).y));
	
	ALBEDO = COLOR.rgb;
	
	if (COLOR.a < 1.0) {
		ALPHA = COLOR.a;
	}
	
	if (debug) {
		float xStretch = 2.0 * uvXStretch;
		float yStretch = 2.0 * uvYStretch;
		float diagStretch = 2.0 * length(vec2(dFdx(UV).y + dFdx(UV).x, dFdy(UV).y + dFdy(UV).x));
		
		ALBEDO = vec3(UV.x, UV.y, 0.0);
		if (UV.x < xStretch || UV.x > 1.0 - xStretch || UV.y < yStretch || UV.y > 1.0 - yStretch || abs(UV.x - (1.-UV.y)) < diagStretch/2.0) {
			ALBEDO = vec3(1.,1.,1.);
		}	
	}
}"

[sub_resource type="ShaderMaterial" id="ShaderMaterial_3dyq5"]
resource_local_to_scene = true
render_priority = 0
shader = SubResource("Shader_ysw6m")
shader_parameter/width = 10.304
shader_parameter/debug = false

[sub_resource type="ArrayMesh" id="ArrayMesh_4k115"]
_surfaces = [{
"aabb": AABB(-16.8745, 0, -19.485, 33.75, 0.001, 29.2285),
"attribute_data": PackedByteArray("+78A/wAAAAAAAIA/+78A/wAAgD8AAIA/+78A/wAAAAAAAAAA+78A/wAAgD8AAAAA+78A/wAAAAAAAIA/+78A/wAAgD8AAIA/+78A/wAAAAAAAAAA+78A/wAAgD8AAAAA+78A/wAAAAAAAIA/+78A/wAAgD8AAIA/+78A/wAAAAAAAAAA+78A/wAAgD8AAAAA+78A/wAAAAAAAIA/+78A/wAAgD8AAIA/+78A/wAAAAAAAAAA+78A/wAAgD8AAAAA"),
"format": 34359742495,
"index_count": 42,
"index_data": PackedByteArray("AAABAAIAAgABAAMAAgADAAQABAADAAUABAAFAAYABgAFAAcABgAHAAgACAAHAAkACAAJAAoACgAJAAsACgALAAwADAALAA0ADAANAA4ADgANAA8A"),
"primitive": 3,
"uv_scale": Vector4(0, 0, 0, 0),
"vertex_count": 16,
"vertex_data": PackedByteArray("+v6GQQAAAABI4RtBBgGHQW8Sgzph5RtBs/ArJwAAAABI4ZvBbxKDOm8Sgzo835vBs/ArJwAAAABI4ZvBbxKDOm8Sgzo835vB+v6GwQAAAABI4RtB7vyGwW8Sgzph5RtB+v6GwQAAAABI4RtB7vyGwW8Sgzph5RtB+v6GQQAAAABI4RtBBgGHQW8Sgzph5RtB+v6GQQAAAABI4RtBBgGHQW8Sgzph5RtBevQAKAAAAABI4ZvBbxKDOm8Sgzo835vBAAAl0VJZgJ4AACXRUlmAngAAJdFSWYCeAAAl0VJZgJ4lUf9/rKaAniVR/3+spoCeJVH/f6ymgJ4lUf9/rKaAnv///3//f/+/////f/9//7////9//3//v////3//f/+/AAAl0VJZgJ4AACXRUlmAngAAJdFSWYCeAAAl0VJZgJ4=")
}]

[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_pj123"]
sky_top_color = Color(0.391974, 0.378214, 0.819851, 1)
sky_horizon_color = Color(0.606717, 0.938473, 0.907229, 1)
ground_bottom_color = Color(0.0901961, 0.027451, 0.109804, 1)
ground_horizon_color = Color(0.76, 0.4028, 0.65284, 1)

[sub_resource type="Sky" id="Sky_xc0y6"]
sky_material = SubResource("ProceduralSkyMaterial_pj123")

[sub_resource type="Environment" id="Environment_vqq6r"]
background_mode = 2
sky = SubResource("Sky_xc0y6")

[node name="DemoScene" type="Node3D"]

[node name="CameraAnimation" type="Node3D" parent="."]
script = ExtResource("4_l381x")

[node name="Camera3D" type="Camera3D" parent="CameraAnimation"]
transform = Transform3D(1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 178.777, 297.104)
fov = 73.1
near = 0.03

[node name="CSGBox3D" type="CSGBox3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.51265, -20.2804, 0.475967)
size = Vector3(573.309, 39.0756, 102.969)

[node name="Outline" type="MeshInstance3D" parent="CSGBox3D"]
transform = Transform3D(6.39, 0, 0, 0, 3.45, 0, 0, 0, 1.125, 0.18924, -23.6928, -0.292213)
material_override = SubResource("ShaderMaterial_a7vdh")
mesh = SubResource("ArrayMesh_2nk65")
skeleton = NodePath("../..")
script = ExtResource("4_1bbda")
radius = 63.03
width = 4.638
color = Color(0.737255, 0.737255, 0.737255, 1)
points = PackedVector3Array(44.5689, 0, 44.5689, 44.5689, 0, -44.5689, -44.5689, 0, -44.5689, -44.5689, 0, 44.5689, 44.5689, 0, 44.5689, 44.5689, 0, -44.5689)

[node name="CSGBox3D2" type="CSGBox3D" parent="CSGBox3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.804047, 45.6447, -0.32209)
size = Vector3(87.0376, 55.5806, 87.3291)

[node name="Outline" type="MeshInstance3D" parent="CSGBox3D/CSGBox3D2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.088562, 28.8565, 0.534744)
material_override = SubResource("ShaderMaterial_o6cm2")
mesh = SubResource("ArrayMesh_wgbw5")
skeleton = NodePath("../../..")
script = ExtResource("4_1bbda")
radius = 61.515
width = 4.638
color = Color(0.737255, 0.737255, 0.737255, 1)
points = PackedVector3Array(43.4977, 0, 43.4977, 43.4977, 0, -43.4977, -43.4977, 0, -43.4977, -43.4977, 0, 43.4977, 43.4977, 0, 43.4977, 43.4977, 0, -43.4977)

[node name="Outline2" type="MeshInstance3D" parent="CSGBox3D/CSGBox3D2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.088562, -25.1604, 0.534744)
material_override = SubResource("ShaderMaterial_ghbnx")
mesh = SubResource("ArrayMesh_dp2ld")
skeleton = NodePath("../../..")
script = ExtResource("4_1bbda")
radius = 63.03
width = 4.638
color = Color(0.737255, 0.737255, 0.737255, 1)
points = PackedVector3Array(44.5689, 0, 44.5689, 44.5689, 0, -44.5689, -44.5689, 0, -44.5689, -44.5689, 0, 44.5689, 44.5689, 0, 44.5689, 44.5689, 0, -44.5689)

[node name="ExampleShapes" type="Node3D" parent="."]

[node name="Line3DAnimation" type="Node3D" parent="ExampleShapes"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -225.601, 35.5271, 0)
script = ExtResource("5_wyyr3")

[node name="Line3D" type="MeshInstance3D" parent="ExampleShapes/Line3DAnimation"]
transform = Transform3D(0.2, 0, 0, 0, 0.2, 0, 0, 0, 0.2, -40.0213, -9.99506, 0)
material_override = SubResource("ShaderMaterial_73ws2")
mesh = SubResource("ArrayMesh_sok3m")
skeleton = NodePath("../../..")
script = ExtResource("4_wvuin")
width = 4.0
color = Color(0.733333, 0.937255, 0, 1)
points = PackedVector3Array(0, 100, 0, 100, 0, 0, 200, 0, 0, 300, 100, 0, 400, 0, 0)

[node name="Line3DUV" type="Node3D" parent="ExampleShapes"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -109.736, 35.5271, 0)

[node name="Line3D" type="MeshInstance3D" parent="ExampleShapes/Line3DUV"]
transform = Transform3D(0.2, 0, 0, 0, 0.2, 0, 0, 0, 0.2, -40.0212, -9.99506, 0)
material_override = SubResource("ShaderMaterial_6a8k2")
mesh = SubResource("ArrayMesh_iwdyf")
skeleton = NodePath("../../..")
script = ExtResource("4_wvuin")
width = 19.538
color = Color(0.494854, 0.494855, 0.494854, 1)
points = PackedVector3Array(0, 100, 0, 100, 0, 0, 200, 0, 0, 300, 100, 0, 400, 0, 0)
debug = true

[node name="HexagonAnimation" type="Node3D" parent="ExampleShapes"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 105.707, 0)
script = ExtResource("5_wyyr3")

[node name="OuterHexagon" type="MeshInstance3D" parent="ExampleShapes/HexagonAnimation"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, 1, 0, -1, -4.37114e-08, 0, 0, 0)
material_override = SubResource("ShaderMaterial_vt35g")
mesh = SubResource("ArrayMesh_a7423")
skeleton = NodePath("../../..")
script = ExtResource("4_1bbda")
sides = 6
radius = 38.75
color = Color(0, 0.882353, 0.929412, 1)
points = PackedVector3Array(19.375, 0, 33.5585, 38.75, 0, 2.37267e-15, 19.375, 0, -33.5585, -19.375, 0, -33.5585, -38.75, 0, -7.11802e-15, -19.375, 0, 33.5585, 19.375, 0, 33.5585, 38.75, 0, 4.62803e-14)

[node name="Node3D2" type="Node3D" parent="ExampleShapes/HexagonAnimation/OuterHexagon"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, -1, 0, 1, -4.37114e-08, 0, 0, 0)
script = ExtResource("5_wyyr3")

[node name="InnerHexagon" type="MeshInstance3D" parent="ExampleShapes/HexagonAnimation/OuterHexagon/Node3D2"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, 1, 0, -1, -4.37114e-08, 0, 0, 0)
material_override = SubResource("ShaderMaterial_7xy0l")
mesh = SubResource("ArrayMesh_mjlf6")
skeleton = NodePath("../../../../..")
script = ExtResource("4_1bbda")
sides = 6
radius = 24.775
width = 2.0
color = Color(0, 0.882353, 0.929412, 1)
points = PackedVector3Array(0, 0, 24.775, 21.4558, 0, 12.3875, 21.4558, 0, -12.3875, 3.03396e-15, 0, -24.775, -21.4558, 0, -12.3875, -21.4558, 0, 12.3875, -6.06792e-15, 0, 24.775, 21.4558, 0, 12.3875)

[node name="Square" type="Node3D" parent="ExampleShapes"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 119.433, 46.877, 0)

[node name="OuterSquare" type="MeshInstance3D" parent="ExampleShapes/Square"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, 1, 0, -1, -4.37114e-08, 0, 0, 0)
material_override = SubResource("ShaderMaterial_x6e0h")
mesh = SubResource("ArrayMesh_sumb6")
skeleton = NodePath("../../..")
script = ExtResource("4_1bbda")
radius = 41.11
width = 1.0
color = Color(0.929412, 0, 0.0156863, 1)
points = PackedVector3Array(29.0692, 0, 29.0692, 29.0692, 0, -29.0692, -29.0692, 0, -29.0692, -29.0692, 0, 29.0692, 29.0692, 0, 29.0692, 29.0692, 0, -29.0692)

[node name="InnerSquareAnimation" type="Node3D" parent="ExampleShapes/Square/OuterSquare"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, -1, 0, 1, -4.37114e-08, 0, 0, 0)
script = ExtResource("5_wyyr3")

[node name="InnerSquare" type="MeshInstance3D" parent="ExampleShapes/Square/OuterSquare/InnerSquareAnimation"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, 1, 0, -1, -4.37114e-08, 0, 0, 0)
material_override = SubResource("ShaderMaterial_54md8")
mesh = SubResource("ArrayMesh_ovykq")
skeleton = NodePath("../../../../..")
script = ExtResource("4_1bbda")
radius = 21.845
width = 1.0
color = Color(0.996078, 0.823529, 0.835294, 1)
points = PackedVector3Array(15.4467, 0, 15.4467, 15.4467, 0, -15.4467, -15.4467, 0, -15.4467, -15.4467, 0, 15.4467, 15.4467, 0, 15.4467, 15.4467, 0, -15.4467)

[node name="Triangle" type="Node3D" parent="ExampleShapes"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 215.628, 46.877, 0)

[node name="Triangle" type="MeshInstance3D" parent="ExampleShapes/Triangle"]
transform = Transform3D(1, 0, 0, 0, -4.37114e-08, -1, 0, 1, -4.37114e-08, 0, 0, 0)
material_override = SubResource("ShaderMaterial_3dyq5")
mesh = SubResource("ArrayMesh_4k115")
skeleton = NodePath("../../..")
script = ExtResource("4_1bbda")
sides = 3
radius = 19.485
width = 10.304
color = Color(0.984314, 0.74902, 0, 1)
points = PackedVector3Array(16.8745, 0, 9.7425, 2.38615e-15, 0, -19.485, -16.8745, 0, 9.7425, 16.8745, 0, 9.7425, 7.15844e-15, 0, -19.485)

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.252069, 0.622031, -0.741308, 0, 0.766044, 0.642788, 0.967709, -0.162027, 0.193096, 0, 0, 0)

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_vqq6r")
        extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(Vector3(.4, 1, .1).normalized(), delta * 4.0);
        extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(Vector3(0.0, 1.0, 0.0), delta * 0.5)
   GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�m�m۬�}�p,��5xi�d�M���)3��$�V������3���$G�$2#�Z��v{Z�lێ=W�~� �����d�vF���h���ڋ��F����1��ڶ�i�엵���bVff3/���Vff���Ҿ%���qd���m�J�}����t�"<�,���`B �m���]ILb�����Cp�F�D�=���c*��XA6���$
2#�E.@$���A.T�p )��#L��;Ev9	Б )��D)�f(qA�r�3A�,#ѐA6��npy:<ƨ�Ӱ����dK���|��m�v�N�>��n�e�(�	>����ٍ!x��y�:��9��4�C���#�Ka���9�i]9m��h�{Bb�k@�t��:s����¼@>&�r� ��w�GA����ը>�l�;��:�
�wT���]�i]zݥ~@o��>l�|�2�Ż}�:�S�;5�-�¸ߥW�vi�OA�x��Wwk�f��{�+�h�i�
4�˰^91��z�8�(��yޔ7֛�;0����^en2�2i�s�)3�E�f��Lt�YZ���f-�[u2}��^q����P��r��v��
�Dd��ݷ@��&���F2�%�XZ!�5�.s�:�!�Њ�Ǝ��(��e!m��E$IQ�=VX'�E1oܪì�v��47�Fы�K챂D�Z�#[1-�7�Js��!�W.3׹p���R�R�Ctb������y��lT ��Z�4�729f�Ј)w��T0Ĕ�ix�\�b�9�<%�#Ɩs�Z�O�mjX �qZ0W����E�Y�ڨD!�$G�v����BJ�f|pq8��5�g�o��9�l�?���Q˝+U�	>�7�K��z�t����n�H�+��FbQ9���3g-UCv���-�n�*���E��A�҂
�Dʶ� ��WA�d�j��+�5�Ȓ���"���n�U��^�����$G��WX+\^�"�h.���M�3�e.
����MX�K,�Jfѕ*N�^�o2��:ՙ�#o�e.
��p�"<W22ENd�4B�V4x0=حZ�y����\^�J��dg��_4�oW�d�ĭ:Q��7c�ڡ��
A>��E�q�e-��2�=Ϲkh���*���jh�?4�QK��y@'�����zu;<-��|�����Y٠m|�+ۡII+^���L5j+�QK]����I �y��[�����(}�*>+���$��A3�EPg�K{��_;�v�K@���U��� gO��g��F� ���gW� �#J$��U~��-��u���������N�@���2@1��Vs���Ŷ`����Dd$R�":$ x��@�t���+D�}� \F�|��h��>�B�����B#�*6��  ��:���< ���=�P!���G@0��a��N�D�'hX�׀ "5#�l"j߸��n������w@ K�@A3�c s`\���J2�@#�_ 8�����I1�&��EN � 3T�����MEp9N�@�B���?ϓb�C��� � ��+�����N-s�M�  ��k���yA 7 �%@��&��c��� �4�{� � �����"(�ԗ�� �t�!"��TJN�2�O~� fB�R3?�������`��@�f!zD��%|��Z��ʈX��Ǐ�^�b��#5� }ى`�u�S6�F�"'U�JB/!5�>ԫ�������/��;	��O�!z����@�/�'�F�D"#��h�a �׆\-������ Xf  @ �q�`��鎊��M��T�� ���0���}�x^�����.�s�l�>�.�O��J�d/F�ě|+^�3�BS����>2S����L�2ޣm�=�Έ���[��6>���TъÞ.<m�3^iжC���D5�抺�����wO"F�Qv�ږ�Po͕ʾ��"��B��כS�p�
��E1e�������*c�������v���%'ž��&=�Y�ް>1�/E������}�_��#��|������ФT7׉����u������>����0����緗?47�j�b^�7�ě�5�7�����|t�H�Ե�1#�~��>�̮�|/y�,ol�|o.��QJ rmϘO���:��n�ϯ�1�Z��ը�u9�A������Yg��a�\���x���l���(����L��a��q��%`�O6~1�9���d�O{�Vd��	��r\�՜Yd$�,�P'�~�|Z!�v{�N�`���T����3?DwD��X3l �����*����7l�h����	;�ߚ�;h���i�0�6	>��-�/�&}% %��8���=+��N�1�Ye��宠p�kb_����$P�i�5�]��:��Wb�����������ě|��[3l����`��# -���KQ�W�O��eǛ�"�7�Ƭ�љ�WZ�:|���є9�Y5�m7�����o������F^ߋ������������������Р��Ze�>�������������?H^����&=����~�?ڭ�>���Np�3��~���J�5jk�5!ˀ�"�aM��Z%�-,�QU⃳����m����:�#��������<�o�����ۇ���ˇ/�u�S9��������ٲG}��?~<�]��?>��u��9��_7=}�����~����jN���2�%>�K�C�T���"������Ģ~$�Cc�J�I�s�? wڻU���ə��KJ7����+U%��$x�6
�$0�T����E45������G���U7�3��Z��󴘶�L�������^	dW{q����d�lQ-��u.�:{�������Q��_'�X*�e�:�7��.1�#���(� �k����E�Q��=�	�:e[����u��	�*�PF%*"+B��QKc˪�:Y��ـĘ��ʴ�b�1�������\w����n���l镲��l��i#����!WĶ��L}rեm|�{�\�<mۇ�B�HQ���m�����x�a�j9.�cRD�@��fi9O�.e�@�+�4�<�������v4�[���#bD�j��W����֢4�[>.�c�1-�R�����N�v��[�O�>��v�e�66$����P
�HQ��9���r�	5FO� �<���1f����kH���e�;����ˆB�1C���j@��qdK|
����4ŧ�f�Q��+�     [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://0ddefkdqn8ht"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
 [remap]

path="res://.godot/exported/133200997/export-9b9c6bdce023f71320d3fd54a9d670ee-Polyline3DMaterial.res"
 list=Array[Dictionary]([{
"base": &"MeshInstance3D",
"class": &"Polyline3D",
"icon": "",
"language": &"GDScript",
"path": "res://addons/ShapesAndLines/Polyline3D.gd"
}, {
"base": &"Polyline3D",
"class": &"VectorShape3D",
"icon": "",
"language": &"GDScript",
"path": "res://addons/ShapesAndLines/VectorShape3D.gd"
}])
   <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="124" height="124" x="2" y="2" fill="#363d52" stroke="#212532" stroke-width="4" rx="14"/><g fill="#fff" transform="translate(12.322 12.322)scale(.101)"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042" transform="translate(12.322 12.322)scale(.101)"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></svg>                 __NKjJ#y3   res://addons/ShapesAndLines/Polyline3DMaterial.tres �'���D   res://Demo/DemoScene.tscnM�U���p   res://icon.svg              ECFG      application/config/name         line renderer 3d   application/run/main_scene$         res://Demo/DemoScene.tscn      application/config/features(   "         4.2    GL Compatibility       application/config/icon         res://icon.svg     dotnet/project/assembly_name         line renderer 3d#   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility