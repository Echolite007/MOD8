%% main.m -- Project backbone: laser-weeding mirror-steering design
%
% Run sections with Ctrl+Enter, or run the whole file.

clear; clc; close all;

%% Paths
addpath('refgen');
addpath('model');
addpath('control');
addpath('spacar');
addpath('spacar\spalight-1.38');

%% System parameters
p = system_parameters();

%% Deliverable b: nominal plant sizing
load('ref_nom.mat','ref_nom')
delB = nominal_plant_sizing(p, ref_nom);

p.mech.r_arm_m       = delB.r_arm_m;
p.mech.J_kgm2        = delB.J_kgm2;
p.mech.k_Nm_per_rad  = delB.k_Nm_per_rad;
p.mech.d_Nms_per_rad = delB.d_Nms_per_rad;

s_var = tf('s');
P_nom = (p.mech.r_arm_m * p.actuator.Kf_N_per_A / p.actuator.R25_ohm) / ...
        (p.mech.J_kgm2 * s_var^2 + p.mech.d_Nms_per_rad * s_var + p.mech.k_Nm_per_rad);
fprintf('\nNominal plant P(s):\n'); P_nom

%% Deliverable c: controller structure
% TODO

%% Deliverable d: loop shaping + tracking error
delD = controller_design_d(p, delB, ref_nom);
fprintf('\nRecommended wc (Approach %s) = %.4f rad/s\n', ...
    delD.recommended, delD.(delD.recommended).wc_rad_s);

%% Save deliverables b and d
save('controllerParam.mat', 'p', 'delB', 'ref_nom', 'delD');
fprintf('\nSaved p, delB, ref_nom, delD to controllerParam.mat\n');

%% Deliverables g, h, i: Spacar model + controller
delGHI = spacarModel(p, delB, delD);

save('controllerParam.mat', 'p', 'delB', 'ref_nom', 'delD', 'delGHI');
fprintf('\nSaved delGHI to controllerParam.mat\n');

%% Deliverable j: discretisation effects + retuning
delJ = discretization(p, delD, delGHI);

save('controllerParam.mat', 'p', 'delB', 'ref_nom', 'delD', 'delGHI', 'delJ');
fprintf('\nSaved delJ to controllerParam.mat\n');

fprintf('\n=== Pipeline summary ===\n');
fprintf('  Spacar wn     : %.2f Hz (%.1f rad/s)\n', delGHI.wn_rad_s/(2*pi), delGHI.wn_rad_s);
fprintf('  delB wn (max) : %.2f Hz (%.1f rad/s)\n', delB.wn_rad_s/(2*pi), delB.wn_rad_s);
fprintf('  Target wc     : %.1f rad/s (%.1f Hz)\n', delGHI.wc_target, delGHI.wc_target/(2*pi));
fprintf('  Actual wc     : %.1f rad/s (%.1f Hz)\n', delGHI.wc_rad_s, delGHI.wc_rad_s/(2*pi));
fprintf('  Phase margin  : %.1f deg\n', delGHI.PM_deg);
fprintf('  Gain margin   : %.1f dB\n',  delGHI.GM_dB);
fprintf('  ---- After discretisation (delJ) ----\n');
fprintf('  Discrete PM   : %.1f deg (retuned)\n', delJ.PM_retuned);
fprintf('  Discrete GM   : %.1f dB  (retuned)\n', delJ.GM_retuned_dB);
fprintf('  Discrete wc   : %.1f rad/s (retuned)\n', delJ.wc_retuned);
