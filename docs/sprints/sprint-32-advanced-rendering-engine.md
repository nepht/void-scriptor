# Sprint 32 — Advanced Rendering Engine

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S32 Advanced Rendering Engine") — hanya judul.
> Step dirancang oleh nephthys dari judul + audit repo nyata: `thumbnail_pipeline` (cache/viewport priority),
> `image_prefetcher`, `environment_lighting_profiles` (data lighting), VFX (data model tanpa render).

## Tujuan

Membangun **render engine** berbasis scene graph + render pipeline yang deterministic dan teruji
unit-level, untuk preview scenographic Void Scriptor. Bukan raw GPU rasterizer.

## Batas lingkup (jujur)

- **IN**: `SceneNode` (hierarchy + transform), `Camera` + viewport (projection, LOD, frustum cull),
  lighting model (ambient/directional/point), material system (base/emission/opacity/texture ref),
  render pipeline (cull → sort → draw stages), render output (render pass → image descriptor),
  post-processing (tone mapping, exposure), UI preview panel, wire route `/render`.
- **OUT**: raw GPU shader (Vulkan/WebGPU/GLSL), ray tracing, mesh polygon rasterization,
  hardware texture sampling, real-time 3D rasterization. Ini engine **scene-graph + pipeline**
  yang menghasilkan deskripsi render deterministik (draw list + projected geometry), bukan framebuffer GPU.

## Step

### Blok A — Scene graph (32.1–32.3)
- **32.1** `SceneNode` (id, name, transform, children, parent; add/remove/find).
- **32.2** `Transform3D` (position/rotation/scale + world matrix compose).
- **32.3** `SceneGraph` (root + traversal pre-order/depth).

### Blok B — Camera + viewport (32.4–32.6)
- **32.4** `Camera` (position, target, fov, near/far, aspect).
- **32.5** View/projection matrix (perspective + lookAt) + world→screen project.
- **32.6** Frustum cull + LOD level by distance.

### Blok C — Lighting (32.7–32.9)
- **32.7** `Light` model (ambient/directional/point + color + intensity).
- **32.8** `LightingProfile` (aggregate lights + compute per-light contribution).
- **32.9** Lighting profile dari DB (`environment_lighting_profiles` mapping).

### Blok D — Material (32.10–32.12)
- **32.10** `Material` (baseColor, emission, opacity, roughness, textureRef).
- **32.11** `MaterialLibrary` (register/lookup by id).
- **32.12** Shade = material × lighting (deterministic color result).

### Blok E — Render pipeline (32.13–32.15)
- **32.13** `Renderable` (mesh proxy: bounds + material + transform).
- **32.14** `RenderPipeline` (cull → sort by depth → draw stages).
- **32.15** `DrawList` (sorted render commands + stats: draw calls, culled count).

### Blok F — Render output + post-process (32.16–32.18)
- **32.16** `RenderPass` (camera + scene → draw list → `RenderFrame`).
- **32.17** `RenderFrame` (framebuffer descriptor: width/height/pixels + depth).
- **32.18** Post-processing: `ToneMapper` (exposure) + output to image descriptor.

### Blok G — UI + wire + DoD (32.19–32.21)
- **32.19** `RenderPreviewPanel` (show render stats + frame descriptor).
- **32.20** Wire route `/render`.
- **32.21** DoD: full regression gates + commit + push + tandai DONE.

## Risiko jujur
- Ini **bukan GPU rasterizer** — geometry diproyeksikan secara matematis (CPU) dan hasilnya
  deskripsi deterministik. Sesuai target Flutter web/desktop tanpa dependency native GPU.
- Produk akhir 3D penuh (mesh polygon + tekstur hardware) tetap butuh engine GPU eksternal
  (mis. flutter_gl / Impeller / integrasi C++) — di luar sprint ini.
