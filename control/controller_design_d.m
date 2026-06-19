function out = controller_design_d(p, delB, ref_nom)
% CONTROLLER_DESIGN_D  Deliverable (d): choose stability margins and gain
% crossover frequency omega_c for a PID + feedforward controller such
% that the closed-loop tracking error meets the +/-0.931 mrad spec, and
% produce the expected tracking-error time plot.
%
% ---------------------------------------------------------------------
% ERROR MODEL (feedforward-compensated lead/PID tracking error)
% ---------------------------------------------------------------------
% Given (course formula, image upload):
%
%   e_LF(t) ~= (beta / (alpha*wc^3)) * [ (1-g1)*dddr(t)
%                                        + (1-g2)*2*zeta*w1*ddr(t)
%                                        + (1-g3)*w1^2*dr(t) ]
%
% with:
%   kj = beta/(alpha*wc^3)
%   ka = 2*zeta*w1 * kj
%   kv = w1^2 * kj
%
% alpha = (1 - sin(45-PM)) / (1 + sin(45-PM))   [from PM via Eq 12.9-style
%                                                 lead/lag relation]
% beta  = design margin constant (given = 2)
% g1,g2,g3 = feedforward gains on jerk/accel/velocity (given = 0.9 each)
% w1 = wn = sqrt(k_eq/J) of the NOMINAL plant from deliverable b
%
% zeta = d / (2*sqrt(J*k_eq)), with d = km^2*r_arm^2/R the BACK-EMF
% damping derived in deliverable b. This is now correctly NON-ZERO
% (earlier versions of this project assumed d=0 "for the nominal
% model", but deliverable b's own voltage formula shows the back-EMF
% damping is built into the plant from the start and cannot be set to
% zero -- it is fixed once r_arm is chosen). zeta and d are pulled
% directly from delB (deliverable b's output) rather than recomputed
% or assumed here, so the two deliverables stay consistent.
%
% ---------------------------------------------------------------------
% SOLVING FOR omega_c -- TWO APPROACHES COMPARED
% ---------------------------------------------------------------------
% Approach A "weeding-only": during the constant-velocity weeding
% phase, ddr = dddr = 0 and dr = v_weeding (constant, NOT the global
% peak |dr| which occurs during the return transient). Setting the
% velocity term alone equal to the error budget:
%
%   kv * (1-g3) * v_weeding = e_max
%   => wc^3 = w1^2 * beta * (1-g3) * v_weeding / (alpha * e_max)
%
% v_weeding = vw/a2p is computed directly here (not hardcoded), and
% matches the original Initialization.m's "0.04655" magic constant to
% 5 decimals once traced back to its source.
%
% Approach B "worst-case, full reference": uses the worst-case PEAK of
% each derivative term over the ENTIRE reference cycle (return +
% weeding), combined via the triangle inequality (sum of absolute
% values, since the three peaks do not necessarily occur at the same
% instant but we want a conservative bound that holds at all t):
%
%   kj*(1-g1)*dddtheta_max + ka*(1-g2)*ddtheta_max + kv*(1-g3)*dtheta_max <= e_max
%
% solved for wc (cubic in wc, since kj/ka/kv all scale as 1/wc^3).
%
% Approach B is more conservative (guarantees the spec at every instant
% of the reference, including the fast return) and is recommended
% unless the deliverable's error spec is explicitly scoped to the
% weeding phase only. Both are computed here so the two can be compared
% directly; out.recommended indicates which this function defaults to
% reporting as "the" design point downstream.
%
% Inputs:
%   p       = system_parameters() struct
%   delB    = nominal_plant_sizing() output struct (provides J, k_eq,
%             d, zeta, r_arm -- ALL consistently derived together)
%   ref_nom = get_reference_peaks() output struct at nominal vw (provides
%             theta_max, dtheta_max, ddtheta_max, dddtheta_max, a2p, and
%             the full time series for the error plot)
%
% Output: struct out with both approaches' wc/kj/ka/kv, margins, and the
%         time-domain expected tracking error for each.

if nargin < 1 || isempty(p);    p    = system_parameters();         end
if nargin < 2 || isempty(delB); error('controller_design_d:delB_required', ...
        'Pass delB from nominal_plant_sizing(p, ref_nom).');        end
if nargin < 3 || isempty(ref_nom); error('controller_design_d:ref_required', ...
        'Pass ref_nom from get_reference_peaks(vw_nom, tw, tr, ts).'); end

%% --- Given design choices ----------------------------------------------
beta = 2;
g1 = 0.9; g2 = 0.9; g3 = 0.9;
PM_deg = delB.zeta*100;   % phase margin choice [deg] -- mid-range of typical 30-45 deg
               % guidance. TODO: revisit/justify explicitly in report.

emax = p.spec.angular_accuracy_rad;   % +/- 0.931 mrad tracking-error spec

%% --- Plant parameters from deliverable b (J, k_eq, d, zeta ALL together) -
J    = delB.J_kgm2;
k_eq = delB.k_Nm_per_rad;
d    = delB.d_Nms_per_rad;   % = km^2*r_arm^2/R, the real back-EMF damping
                              % (NOT zero -- see deliverable b derivation)
zeta = delB.zeta;            % = d/(2*sqrt(J*k_eq)), consistent with d above
w1   = delB.wn_rad_s;        % = sqrt(k_eq/J), the plant's own natural frequency

%% --- alpha from phase margin (Eq. 12.9-style lead relation) ------------
alpha = (1 - sind(45 - PM_deg)) / (1 + sind(45 - PM_deg));

%% --- Reference quantities ------------------------------------------------
% Weeding-phase constant angular velocity (NOT the global peak |dr|,
% which occurs during the fast return transient -- see header).
v_weeding = p.spec.driving_speed_nom_mps / ref_nom.a2p;

dtheta_max   = ref_nom.dtheta_max;    % global peak |dr|  (return transient)
ddtheta_max  = ref_nom.ddtheta_max;   % global peak |ddr| (return transient)
dddtheta_max = ref_nom.dddtheta_max;  % global peak |dddr|(return transient)

%% ========================================================================
%  APPROACH A: weeding-phase velocity term only
%  ========================================================================
wcA3 = w1^2 * beta * (1 - g3) * v_weeding / (alpha * emax);
wcA  = wcA3^(1/3);

kjA = beta / (alpha * wcA^3);
kaA = 2 * zeta * w1 * kjA;   % now non-zero since zeta is non-zero
kvA = w1^2 * kjA;

%% ========================================================================
%  APPROACH B: worst-case sum over full reference (return + weeding)
%  ========================================================================
% kj(1-g1)*dddtheta_max + ka(1-g2)*ddtheta_max + kv(1-g3)*dtheta_max = emax
% kj, ka, kv all carry a common factor beta/(alpha*wc^3), so this still
% reduces to a cubic in wc:
%   (beta/(alpha*wc^3)) * [ (1-g1)*dddtheta_max + (1-g2)*2*zeta*w1*ddtheta_max
%                          + (1-g3)*w1^2*dtheta_max ] = emax
rhs_B = (1 - g1) * dddtheta_max + (1 - g2) * 2 * zeta * w1 * ddtheta_max + (1 - g3) * w1^2 * dtheta_max;
wcB3  = beta * rhs_B / (alpha * emax);
wcB   = wcB3^(1/3);

kjB = beta / (alpha * wcB^3);
kaB = 2 * zeta * w1 * kjB;
kvB = w1^2 * kjB;

%% ========================================================================
%  Expected tracking-error time plots, both approaches, full reference
%  ========================================================================
t    = ref_nom.t;
dr   = ref_nom.dr;
ddr  = ref_nom.ddr;
dddr = ref_nom.dddr;

e_A = kjA*(1-g1)*dddr + kaA*(1-g2)*ddr + kvA*(1-g3)*dr;
e_B = kjB*(1-g1)*dddr + kaB*(1-g2)*ddr + kvB*(1-g3)*dr;

figure('Color','w','Position',[100 100 900 500]);
plot(t*1e3, e_A*1e3, 'LineWidth', 1.5); hold on;
plot(t*1e3, e_B*1e3, 'LineWidth', 1.5);
yline( emax*1e3, '--k', 'LineWidth', 1);
yline(-emax*1e3, '--k', 'LineWidth', 1);
xline(p.spec.return_time_s*1e3, ':', 'Color', [0.5 0.5 0.5]);
xlabel('Time [ms]');
ylabel('Tracking error e_{LF} [mrad]');
legend('Approach A (weeding-only \omega_c)', 'Approach B (worst-case \omega_c)', ...
       '\pm spec (0.931 mrad)', 'Location', 'best');
title('Deliverable (d): expected tracking error vs. spec');
grid on;
box on;

maxAbsErrA = max(abs(e_A));
maxAbsErrB = max(abs(e_B));
specOkA = maxAbsErrA <= emax;
specOkB = maxAbsErrB <= emax;

fprintf('--- Deliverable d: controller design (PM=%.0f deg) ---\n', PM_deg);
fprintf('alpha = %.4f, beta = %.1f, zeta = %.6g (from delB, d=%.6g N*m*s/rad, NOT zero), w1 = %.4f rad/s\n', ...
    alpha, beta, zeta, d, w1);
fprintf('emax (spec)  = %.4f mrad\n\n', emax*1e3);

fprintf('Approach A (weeding-phase velocity term only, v_weeding=%.6f rad/s):\n', v_weeding);
fprintf('  wc = %.4f rad/s (%.3f Hz)\n', wcA, wcA/(2*pi));
fprintf('  kj=%.6g, ka=%.6g, kv=%.6g\n', kjA, kaA, kvA);
fprintf('  max|e(t)| over FULL reference = %.4f mrad  -> %s\n\n', maxAbsErrA*1e3, ternary(specOkA,'OK','SPEC VIOLATED'));

fprintf('Approach B (worst-case sum, full reference incl. return):\n');
fprintf('  wc = %.4f rad/s (%.3f Hz)\n', wcB, wcB/(2*pi));
fprintf('  kj=%.6g, ka=%.6g, kv=%.6g\n', kjB, kaB, kvB);
fprintf('  max|e(t)| over FULL reference = %.4f mrad  -> %s\n', maxAbsErrB*1e3, ternary(specOkB,'OK','SPEC VIOLATED'));

if ~specOkA
    fprintf(['\nNOTE: Approach A only enforces the spec during the weeding phase by\n', ...
             'construction; the fast return transient is NOT covered and can exceed\n', ...
             'the +/-0.931 mrad bound, as shown in the plot and confirmed above.\n']);
end

out = struct();
out.PM_deg = PM_deg;
out.alpha = alpha;
out.beta = beta;
out.zeta = zeta;
out.w1_rad_s = w1;
out.emax_rad = emax;
out.v_weeding_rad_s = v_weeding;

out.A = struct('wc_rad_s', wcA, 'kj', kjA, 'ka', kaA, 'kv', kvA, ...
                'max_abs_err_rad', maxAbsErrA, 'spec_ok', specOkA, 'e_t', e_A);
out.B = struct('wc_rad_s', wcB, 'kj', kjB, 'ka', kaB, 'kv', kvB, ...
                'max_abs_err_rad', maxAbsErrB, 'spec_ok', specOkB, 'e_t', e_B);
out.t = t;
out.recommended = 'B';   % worst-case approach recommended: guarantees spec at all t

end

function s = ternary(cond, a, b)
if cond; s = a; else; s = b; end
end
