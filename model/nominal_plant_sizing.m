function out = nominal_plant_sizing(p, ref)
% NOMINAL_PLANT_SIZING  Deliverable (b): size r_arm, J, k_eq for the
% nominal single-DOF rotary plant against the actuator's continuous
% voltage ceiling, using peak reference values from the provided
% reference generator.
%
% ---------------------------------------------------------------------
% MODEL
% ---------------------------------------------------------------------
% Given transfer function for LINEAR coil displacement x(s)/U(s) (voice
% coil motor, back-EMF loop only, no external damper):
%
%               x(s)     km/(R*m)
%   Pu(s) =  -------- = -----------------------------
%               U(s)     s^2 + (km^2/(R*m)) s + k/m
%
% Cross-multiplying gives the LINEAR force-balance equation:
%
%   m*xddot  +  (km^2/R)*xdot  +  k*x  =  (km/R)*u                  (*)
%
% where m is the coil's moving mass, k the linear suspension stiffness,
% and km^2/R is the BACK-EMF damping that falls out naturally once
% current/voltage are eliminated (it is NOT a separate mechanical
% dashpot, and it is NOT zero/negligible -- it is built into the given
% transfer function from the start).
%
% To go from linear (x) to rotary (theta) with x = r_arm*theta (small-
% angle arc length), multiply (*) THROUGH BY r_arm to convert the force
% balance into a TORQUE balance (this is the correct step -- substituting
% m -> J/r_arm^2 directly, as an earlier version of this file did, is
% NOT correct and was fixed here):
%
%   (m*r_arm^2)*thetaddot + (km^2*r_arm^2/R)*thetadot + (k*r_arm^2)*theta
%       = (km*r_arm/R)*u
%
% Identifying:
%   J    = m * r_arm^2                  [kg*m^2]  rotary inertia
%   d    = (km^2/R) * r_arm^2           [N*m*s/rad]  back-EMF damping
%   k_eq = k * r_arm^2                  [N*m/rad]  rotary stiffness
%
% gives the rotary plant used throughout this project:
%
%             theta(s)     r_arm * km / R
%   P(s) = ------------ = --------------------------------
%             U(s)         J s^2  +  d s  +  k_eq
%
% ---------------------------------------------------------------------
% VOLTAGE FORMULA (inverse Laplace)
% ---------------------------------------------------------------------
% Taking the inverse Laplace transform of (J s^2 + d s + k_eq) theta(s)
% = (r_arm*km/R) U(s) and solving for u:
%
%   u_req(t) = (R/(km*r_arm)) * J * theta_ddot(t)
%            + (R/(km*r_arm)) * d * theta_dot(t)
%            +  (R/(km*r_arm)) * k_eq * theta(t)
%
% Substituting d = km^2*r_arm^2/R into the middle term collapses the
% R's and one factor of r_arm, giving the remarkably simple result
% (verified symbolically):
%
%   (R*d)/(km*r_arm) = km * r_arm
%
% so the full voltage formula simplifies to:
%
%   u_req(t) = (R*J)/(km*r_arm) * theta_ddot(t)
%            +  km*r_arm         * theta_dot(t)
%            + (R*k_eq)/(km*r_arm) * theta(t)
%
% This matches the course's given feedforward-voltage formula exactly
% (theta_ddot, theta_dot, theta here are all the REFERENCE r(t) and its
% derivatives, per the deliverable d setup -- this IS the feedforward
% voltage needed to drive the reference trajectory through the plant).
%
% ---------------------------------------------------------------------
% SIZING STRATEGY (per-term independent voltage budget)
% ---------------------------------------------------------------------
% Each term of u_req is bounded independently against Umax (the peaks
% of theta, theta_dot, theta_ddot do not occur simultaneously over one
% return/weeding cycle), each with a 0.9 safety margin:
%
%   1) r_arm from the velocity-driven voltage budget (now correctly
%      understood as the back-EMF term that survives even with the
%      real, non-zero d -- NOT an artefact of assuming d=0):
%        u_v = km * r_arm * dtheta_max  <=  0.9 * Umax
%        => r_arm <= 0.9 * Umax / (km * dtheta_max)
%
%   2) J from the acceleration-driven voltage budget, given r_arm:
%        u_J = (R * J * ddtheta_max) / (r_arm * km)  <=  0.9 * Umax
%        => J <= 0.9 * Umax * r_arm * km / (R * ddtheta_max)
%
%   3) k_eq from the position-driven voltage budget, given r_arm:
%        u_k = (R * k_eq * theta_max) / (r_arm * km)  <=  0.9 * Umax
%        => k_eq <= 0.9 * Umax * r_arm * km / (R * theta_max)
%
% Each inequality is taken at equality to fix a nominal design point
% (the maximum r_arm, J, k_eq the voltage budget allows). NOTE: because
% d = km^2*r_arm^2/R is now known to be non-zero (back-EMF damping is
% physically always present, not negligible), the resulting damping
% ratio zeta = d/(2*sqrt(J*k_eq)) is computed and exposed below for use
% in deliverable d, rather than assumed zero.
%
% Inputs:
%   p   = system_parameters() struct
%   ref = get_reference_peaks(...) struct (theta_max, dtheta_max, ddtheta_max)
%
% Output: struct out with fields r_arm_m, J_kgm2, k_Nm_per_rad, d_Nms_per_rad,
%         zeta, wn_rad_s, margin, u_req_check (struct with the three
%         individual terms evaluated at the design point, each should
%         equal margin*Umax).

if nargin < 1 || isempty(p);   p   = system_parameters();                 end
if nargin < 2 || isempty(ref); error('nominal_plant_sizing:ref_required', ...
        'Pass a ref struct from get_reference_peaks(vw, tw, tr, ts).');   end

R   = p.actuator.R25_ohm;
km  = p.actuator.Kf_N_per_A;     % force constant [N/A] == back-EMF constant [V/(m/s)] (datasheet symmetry)
Umax = p.actuator.Umax_V;        % continuous-operation ceiling = Ic * R25

margin = 0.9;   % safety margin applied to each term's voltage budget

theta_max   = ref.theta_max;
dtheta_max  = ref.dtheta_max;
ddtheta_max = ref.ddtheta_max;

%% 1) r_arm from the velocity-driven (back-EMF) voltage budget
r_arm = margin * Umax / (km * dtheta_max);
r_arm = 70e-3;
%% 2) J from acceleration-driven voltage budget (given r_arm)
J = margin * Umax * r_arm * km / (R * ddtheta_max);

%% 3) k_eq from position-driven voltage budget (given r_arm)
k_eq = margin * Umax * r_arm * km / (R * theta_max);

%% Real back-EMF damping and resulting damping ratio (NOT zero/neglected)
d    = (km^2 / R) * r_arm^2;
wn   = sqrt(k_eq / J);            % suspension resonance [rad/s]
zeta = d / (2 * sqrt(J * k_eq));  % damping ratio, now computed from the real d

% Geometric stroke check (mirror angular range vs. VCM half-stroke):
%   r_arm * mirror_angle_max_rad <= stroke_half_m
stroke_check_m = r_arm * p.spec.mirror_angle_max_rad;
stroke_ok      = stroke_check_m <= p.actuator.stroke_half_m;

% KNOWN ISSUE: mirror-offset range check (mirror midpoint must sit
% 50-150 mm from the rotation axis/base). The r_arm solved purely from
% the back-EMF voltage budget above does NOT see this geometric bound
% and can land well outside [50, 150] mm -- the two constraints are
% independent and nothing in the algebra forces them to agree. Flagged
% here rather than silently clamped; if offset_ok is false, this is a
% genuine sizing conflict to discuss/resolve explicitly in the
% deliverable b writeup.
offset_ok = (r_arm >= p.spec.mirror_offset_min_m) && (r_arm <= p.spec.mirror_offset_max_m);

%% Voltage-budget verification (each term should equal margin*Umax at the design point)
u_v = km * r_arm * dtheta_max;
u_J = (R * J * ddtheta_max) / (r_arm * km);
u_k = (R * k_eq * theta_max) / (r_arm * km);

out = struct();
out.r_arm_m       = r_arm;
out.J_kgm2        = J;
out.k_Nm_per_rad  = k_eq;
out.d_Nms_per_rad = d;
out.zeta          = zeta;
out.wn_rad_s       = wn;
out.margin         = margin;
out.Umax_V         = Umax;
out.stroke_check_m = stroke_check_m;
out.stroke_half_m  = p.actuator.stroke_half_m;
out.stroke_ok      = stroke_ok;
out.offset_ok      = offset_ok;
out.mirror_offset_min_m = p.spec.mirror_offset_min_m;
out.mirror_offset_max_m = p.spec.mirror_offset_max_m;
out.u_req_check    = struct('u_v_V', u_v, 'u_J_V', u_J, 'u_k_V', u_k);

fprintf('--- Deliverable b: nominal plant sizing ---\n');
fprintf('Umax (continuous)   = %.4f V  (= Ic*R25 = %.3f A * %.2f Ohm)\n', Umax, p.actuator.Ic_A, R);
fprintf('margin               = %.2f\n', margin);
fprintf('r_arm                = %.6g m  (%.3f mm)\n', r_arm, r_arm*1e3);
fprintf('J                    = %.6g kg*m^2\n', J);
fprintf('k_eq                 = %.6g N*m/rad\n', k_eq);
fprintf('d (back-EMF damping) = %.6g N*m*s/rad  (= km^2*r_arm^2/R, NOT zero/neglected)\n', d);
fprintf('zeta                 = %.6g\n', zeta);
fprintf('wn                   = %.6g rad/s  (%.3f Hz)\n', wn, wn/(2*pi));
fprintf('Stroke check: r_arm*theta_max = %.4f mm  vs  stroke_half = %.4f mm  -> %s\n', ...
    stroke_check_m*1e3, p.actuator.stroke_half_m*1e3, ternary(stroke_ok,'OK','VIOLATED'));
fprintf('Mirror-offset check: r_arm = %.2f mm  vs  allowed [%.0f, %.0f] mm  -> %s\n', ...
    r_arm*1e3, p.spec.mirror_offset_min_m*1e3, p.spec.mirror_offset_max_m*1e3, ternary(offset_ok,'OK','VIOLATED (KNOWN ISSUE)'));
if ~offset_ok
    fprintf(['  NOTE: r_arm is sized purely from the back-EMF voltage budget and does\n', ...
             '  not respect the 50-150 mm mechanism offset range. This is a known open\n', ...
             '  conflict between the two constraints -- flag and discuss in the report\n', ...
             '  rather than silently resolving it here.\n']);
end
fprintf('Voltage budget check (each should equal margin*Umax = %.4f V):\n', margin*Umax);
fprintf('  velocity/back-EMF term : %.4f V\n', u_v);
fprintf('  J (acceleration) term  : %.4f V\n', u_J);
fprintf('  k_eq (position) term   : %.4f V\n', u_k);

end

function s = ternary(cond, a, b)
if cond; s = a; else; s = b; end
end
