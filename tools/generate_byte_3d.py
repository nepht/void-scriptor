"""Generate the lightweight, application-owned Byte mascot GLB."""

from pathlib import Path
import math

import numpy as np
import trimesh
from pygltflib import (
    FLOAT,
    SCALAR,
    VEC3,
    VEC4,
    Accessor,
    Animation,
    AnimationChannel,
    AnimationChannelTarget,
    AnimationSampler,
    BufferView,
    GLTF2,
    Node,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "models" / "byte_mascot_v1.glb"


def material(name, color, metallic=0.0, roughness=0.45, emission=None):
    return trimesh.visual.material.PBRMaterial(
        name=name,
        baseColorFactor=color,
        metallicFactor=metallic,
        roughnessFactor=roughness,
        emissiveFactor=emission,
    )


WHITE = material("Byte ceramic armor", [235, 242, 255, 255], 0.25, 0.22)
BLACK = material("Byte black glass", [5, 10, 20, 255], 0.62, 0.12)
METAL = material("Byte dark joints", [24, 29, 42, 255], 0.88, 0.2)
BLUE = material(
    "Byte blue light", [20, 120, 255, 255], 0.15, 0.18, [0.15, 0.65, 1.0]
)
CRYSTAL = material(
    "Byte translucent crystal", [75, 160, 255, 210], 0.18, 0.08, [0.12, 0.42, 1.0]
)


scene = trimesh.Scene(base_frame="ByteRoot")


def add(mesh, name, mat, scale=None, translation=None, transform=None):
    mesh = mesh.copy()
    if scale is not None:
        mesh.apply_scale(scale)
    if transform is not None:
        mesh.apply_transform(transform)
    if translation is not None:
        mesh.apply_translation(translation)
    mesh.visual.material = mat
    scene.add_geometry(mesh, node_name=name, geom_name=f"{name}Mesh")
    return mesh


def sphere(name, location, scale, mat, subdivisions=2):
    return add(
        trimesh.creation.icosphere(subdivisions=subdivisions, radius=1),
        name,
        mat,
        scale=scale,
        translation=location,
    )


def capsule_between(name, start, end, radius, mat):
    start = np.asarray(start, dtype=float)
    end = np.asarray(end, dtype=float)
    direction = end - start
    length = float(np.linalg.norm(direction))
    mesh = trimesh.creation.capsule(radius=radius, height=max(0.02, length - 2 * radius))
    alignment = trimesh.geometry.align_vectors([0, 0, 1], direction)
    alignment[:3, 3] = (start + end) / 2
    return add(mesh, name, mat, transform=alignment)


def disk(name, location, radius, depth, mat):
    mesh = trimesh.creation.cylinder(radius=radius, height=depth, sections=32)
    rotation = trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0])
    return add(mesh, name, mat, transform=rotation, translation=location)


def crystal(name, location, radius, height, mat=CRYSTAL, tilt=0.0):
    sides = 6
    vertices = [[0, 0, height / 2], [0, 0, -height / 2]]
    for index in range(sides):
        angle = 2 * math.pi * index / sides
        vertices.append([radius * math.cos(angle), radius * math.sin(angle), 0])
    faces = []
    for index in range(sides):
        a = 2 + index
        b = 2 + (index + 1) % sides
        faces.extend([[0, a, b], [1, b, a]])
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces, process=True)
    rotation = trimesh.transformations.rotation_matrix(tilt, [0, 1, 0])
    return add(mesh, name, mat, transform=rotation, translation=location)


# Head, face, expression, and identity lights.
sphere("ByteHead", [0, 0, 2.52], [1.12, 0.72, 0.84], WHITE, 3)
sphere("ByteFace", [0, -0.66, 2.43], [0.82, 0.12, 0.52], BLACK, 3)
sphere("ByteEyeLeft", [-0.28, -0.785, 2.47], [0.13, 0.045, 0.22], BLUE)
sphere("ByteEyeRight", [0.28, -0.785, 2.47], [0.13, 0.045, 0.22], BLUE)
for index, (x, z) in enumerate([(-0.09, 2.19), (0, 2.16), (0.09, 2.19)]):
    sphere(f"ByteSmile{index}", [x, -0.79, z], [0.06, 0.025, 0.035], BLUE, 1)
crystal("ByteCrystalForehead", [0, -0.72, 2.84], 0.11, 0.24)

# Four recognizable crystal fins.
for name, location, tilt in [
    ("ByteCrystalUpperLeft", [-0.74, 0, 3.25], -0.34),
    ("ByteCrystalUpperRight", [0.74, 0, 3.25], 0.34),
    ("ByteCrystalLowerLeft", [-0.94, 0.02, 2.83], -0.62),
    ("ByteCrystalLowerRight", [0.94, 0.02, 2.83], 0.62),
]:
    crystal(name, location, 0.16, 0.65 if "Upper" in name else 0.48, tilt=tilt)

# Torso and chest infinity mark.
sphere("ByteTorso", [0, 0, 1.35], [0.64, 0.46, 0.7], WHITE, 3)
sphere("ByteWaist", [0, 0, 0.78], [0.43, 0.35, 0.3], METAL, 2)
disk("ByteChest", [0, -0.49, 1.45], 0.31, 0.09, BLACK)
for side in (-1, 1):
    ring = trimesh.creation.torus(major_radius=0.105, minor_radius=0.027, major_sections=24)
    rotation = trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0])
    rotation[:3, 3] = [side * 0.09, -0.55, 1.45]
    add(ring, f"ByteInfinity{'Left' if side < 0 else 'Right'}", BLUE, transform=rotation)

# Arms and hands.
for side, label in [(-1, "Left"), (1, "Right")]:
    sphere(f"ByteShoulder{label}", [side * 0.62, 0, 1.55], [0.25, 0.27, 0.25], WHITE)
    capsule_between(
        f"ByteUpperArm{label}",
        [side * 0.68, 0, 1.43],
        [side * 0.82, -0.02, 1.02],
        0.16,
        WHITE,
    )
    sphere(f"ByteElbow{label}", [side * 0.84, -0.02, 0.94], [0.17] * 3, METAL)
    capsule_between(
        f"ByteForearm{label}",
        [side * 0.85, -0.02, 0.88],
        [side * 0.92, -0.12, 0.56],
        0.15,
        WHITE,
    )
    sphere(f"ByteHand{label}", [side * 0.94, -0.14, 0.42], [0.2, 0.16, 0.18], METAL)

# Legs and feet.
for side, label in [(-1, "Left"), (1, "Right")]:
    sphere(f"ByteHip{label}", [side * 0.32, 0, 0.74], [0.24] * 3, METAL)
    capsule_between(
        f"ByteThigh{label}", [side * 0.34, 0, 0.69], [side * 0.37, 0, 0.35], 0.21, WHITE
    )
    sphere(f"ByteKnee{label}", [side * 0.37, -0.08, 0.3], [0.21, 0.19, 0.2], METAL)
    capsule_between(
        f"ByteShin{label}", [side * 0.37, 0, 0.26], [side * 0.38, -0.02, 0.04], 0.2, WHITE
    )
    sphere(f"ByteFoot{label}", [side * 0.38, -0.13, -0.12], [0.28, 0.38, 0.18], WHITE)
    sphere(f"ByteFootLight{label}", [side * 0.38, -0.46, -0.09], [0.13, 0.04, 0.06], BLUE, 1)

# Segmented curious tail and its crystal tip.
tail_points = [
    [0.45, 0.26, 0.9],
    [0.78, 0.32, 0.98],
    [1.06, 0.26, 0.83],
    [1.2, 0.05, 0.57],
    [1.17, -0.08, 0.28],
]
for index in range(len(tail_points) - 1):
    capsule_between(
        f"ByteTail{index}", tail_points[index], tail_points[index + 1], 0.09, WHITE if index % 2 == 0 else METAL
    )
crystal("ByteCrystalTail", [1.17, -0.1, 0.05], 0.17, 0.55, tilt=0.18)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_bytes(scene.export(file_type="glb"))

# Add a shared root and a subtle embedded idle animation. The model stays
# usable without animation, while GLB-capable clients can play the clip.
gltf = GLTF2().load_binary(str(OUTPUT))
root_children = list(gltf.scenes[gltf.scene].nodes or [])
root_index = len(gltf.nodes)
gltf.nodes.append(Node(name="ByteRigRoot", children=root_children))
gltf.scenes[gltf.scene].nodes = [root_index]

blob = bytearray(gltf.binary_blob() or b"")


def append_accessor(values, accessor_type, count, minimum=None, maximum=None):
    while len(blob) % 4:
        blob.append(0)
    offset = len(blob)
    packed = np.asarray(values, dtype="<f4").tobytes()
    blob.extend(packed)
    view_index = len(gltf.bufferViews)
    gltf.bufferViews.append(BufferView(buffer=0, byteOffset=offset, byteLength=len(packed)))
    accessor_index = len(gltf.accessors)
    gltf.accessors.append(
        Accessor(
            bufferView=view_index,
            byteOffset=0,
            componentType=FLOAT,
            count=count,
            type=accessor_type,
            min=minimum or [],
            max=maximum or [],
        )
    )
    return accessor_index


times = [0.0, 0.6, 1.2, 1.8, 2.4]
time_accessor = append_accessor(times, SCALAR, len(times), [0.0], [2.4])
tilts = [0.0, -0.07, 0.0, 0.07, 0.0]
rotations = []
for angle in tilts:
    rotations.extend([0.0, math.sin(angle / 2), 0.0, math.cos(angle / 2)])
rotation_accessor = append_accessor(rotations, VEC4, len(times))
translations = []
for z in [0.0, 0.035, 0.065, 0.035, 0.0]:
    translations.extend([0.0, 0.0, z])
translation_accessor = append_accessor(translations, VEC3, len(times))

gltf.animations.append(
    Animation(
        name="ByteCuriousIdle",
        samplers=[
            AnimationSampler(input=time_accessor, output=rotation_accessor, interpolation="LINEAR"),
            AnimationSampler(input=time_accessor, output=translation_accessor, interpolation="LINEAR"),
        ],
        channels=[
            AnimationChannel(sampler=0, target=AnimationChannelTarget(node=root_index, path="rotation")),
            AnimationChannel(sampler=1, target=AnimationChannelTarget(node=root_index, path="translation")),
        ],
    )
)
gltf.buffers[0].byteLength = len(blob)
gltf.set_binary_blob(bytes(blob))
gltf.save_binary(str(OUTPUT))
print(f"WROTE {OUTPUT} ({OUTPUT.stat().st_size} bytes)")
print(f"GEOMETRIES {len(scene.geometry)} NODES {len(scene.graph.nodes_geometry)}")
