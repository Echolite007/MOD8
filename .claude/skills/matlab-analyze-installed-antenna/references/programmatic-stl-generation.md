# Programmatic STL Generation for Platforms

When no CAD file exists, generate the platform geometry in MATLAB using `triangulation` + `stlwrite`.

## Open-Ended Cylinder (Tube / Cavity)

```matlab
radius = 0.05; height = 0.15; nPts = 24;
theta = linspace(0, 2*pi, nPts+1); theta(end) = [];  % avoid duplicate vertex
xBot = radius*cos(theta); yBot = radius*sin(theta);
zBot = -height/2 * ones(size(theta));
xTop = radius*cos(theta); yTop = radius*sin(theta);
zTop = height/2 * ones(size(theta));
verts = [xBot(:), yBot(:), zBot(:); xTop(:), yTop(:), zTop(:)];
faces = [];
for i = 1:nPts
    j = mod(i, nPts) + 1;
    faces = [faces; i, i+nPts, j; j, i+nPts, j+nPts];
end
TR = triangulation(faces, verts);
stlwrite(TR, fullfile(tempdir, "tube.stl"));
plat = platform(FileName=fullfile(tempdir, "tube.stl"), Units="m");
```

## Flat Rectangular Plate

```matlab
Lx = 0.5; Ly = 0.3;  % plate dimensions in meters
verts = [-Lx/2, -Ly/2, 0; Lx/2, -Ly/2, 0; Lx/2, Ly/2, 0; -Lx/2, Ly/2, 0];
faces = [1 2 3; 1 3 4];
TR = triangulation(faces, verts);
stlwrite(TR, fullfile(tempdir, "plate.stl"));
plat = platform(FileName=fullfile(tempdir, "plate.stl"), Units="m");
```

Note: The built-in `"plate.stl"` ships with Antenna Toolbox and is preferred for quick tests.

## Box (Closed Enclosure)

```matlab
Lx = 0.3; Ly = 0.2; Lz = 0.1;  % box dimensions in meters
x = Lx/2; y = Ly/2; z = Lz/2;
verts = [
    -x,-y,-z; x,-y,-z; x,y,-z; -x,y,-z;
    -x,-y, z; x,-y, z; x,y, z; -x,y, z];
faces = [
    1 3 2; 1 4 3;   % bottom
    5 6 7; 5 7 8;   % top
    1 2 6; 1 6 5;   % front
    2 3 7; 2 7 6;   % right
    3 4 8; 3 8 7;   % back
    4 1 5; 4 5 8];  % left
TR = triangulation(faces, verts);
stlwrite(TR, fullfile(tempdir, "box.stl"));
plat = platform(FileName=fullfile(tempdir, "box.stl"), Units="m");
```

## Tips for Clean STL Meshes

- **Avoid duplicate vertices at seams** — use `theta(end) = []` for periodic geometry
- **Open structures** (tubes, cavities) work reliably with FMM/EFIE
- **Closed bodies** require watertight mesh (no gaps) for CFIE/MFIE
- **Use `stlFileChecker`** if `platform` reports "Bad features in STL file"
- **Face normals must be consistent** — outward-facing for closed bodies
- **Keep triangle count reasonable** — `nPts=24` for cylinders is sufficient; denser meshes slow down the solver without improving accuracy (the platform is remeshed anyway)

## Solver Considerations for Programmatic Geometry

| Geometry | Recommended Solver | Formulation | Notes |
|----------|-------------------|-------------|-------|
| Open tube/cavity | FMM | EFIE | Correctly models shielding from walls |
| Closed box/sphere | FMM | CFIE | Best convergence for watertight meshes |
| Flat plate | MoM-PO | — | Default, fast for open surfaces |

----

Copyright 2026 The MathWorks, Inc.
