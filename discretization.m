function delJ = discretization(p, delD, delGHI)
% DISCRETIZATION  Deliverable j: effect of discretisation on wc and
% stability margins, and retuning if needed.
%
% Inputs:  p (system_parameters), delD (controller sizing),
%          delGHI (Spacar model + continuous PID design, from spacarModel.m)
% Output:  delJ struct with discrete plant, controller, and margins
%
% Methods:
%   Plant      -> Zero-Order Hold (ZoH). The DAC physically holds the
%                 actuator voltage constant between samples, so ZoH is
%                 the exact discretisation, not a design choice.
%   Controller -> Tustin (bilinear). Best phase approximation below
%                 Nyquist among standard methods; preserves the
%                 stability boundary (jw-axis -> unit circle) exactly.
%                 Direct discrete-TF implementation in hardware is not
%                 advised (hard to retune, hard to add anti-windup);
%                 use a discrete PID block instead.

s_tf  = tf('s');
ts    = p.ctrl.ts_s;
wc    = delGHI.wc_target;
sysem = delGHI.sysem;
C_PID = delGHI.C_PID;
OL_cont = delGHI.OL;
m_eq  = delGHI.m_eq;
beta  = delD.beta;

fprintf('\n=== Deliverable j: discretisation setup ===\n');
fprintf('  ts = %.5f s  (fs = %.0f Hz)\n', ts, 1/ts);
fprintf('  Nyquist = %.0f rad/s (%.0f Hz)\n', pi/ts, 1/(2*ts));
fprintf('  wc_target = %.1f rad/s (%.1f Hz),  wc/Nyquist = %.3f\n', ...
        wc, wc/(2*pi), wc/(pi/ts));

%% ---- Step j.1: Discretise plant (ZoH) and controller (Tustin) --------
Pz_zoh    = c2d(sysem, ts, 'zoh');
Cz_tustin = c2d(C_PID, ts, 'tustin');
OL_disc   = Cz_tustin * Pz_zoh;
CL_disc   = feedback(OL_disc, 1);

[GM_c,PM_c,wpc_c,wgc_c] = margin(OL_cont);
[GM_d,PM_d,wpc_d,wgc_d] = margin(OL_disc);

fprintf('\n=== Step 1: Continuous vs discretised (original alpha) ===\n');
fprintf('  Continuous:  wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB (at %.1f rad/s)\n', ...
        wgc_c, PM_c, 20*log10(GM_c), wpc_c);
fprintf('  Discrete:    wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB (at %.1f rad/s)\n', ...
        wgc_d, PM_d, 20*log10(GM_d), wpc_d);
fprintf('  PM loss: %.1f deg   wc shift: %.2f%%\n', PM_c-PM_d, (wgc_d-wgc_c)/wgc_c*100);

n_unstable_d = sum(abs(pole(CL_disc))>1);
if n_unstable_d==0
    fprintf('  Closed-loop STABLE (discrete, original alpha)\n');
else
    fprintf('  WARNING: Closed-loop UNSTABLE (discrete, original alpha)\n');
end

%% ---- Step j.2: Quantify phase-lag source (ZoH half-sample delay) ------
phi_ZoH_approx = ts * wgc_c / 2 * (180/pi);
wc_warped = 2/ts * tan(wgc_c*ts/2);
fprintf('\n=== Step 2: Phase-lag breakdown at wc=%.1f rad/s ===\n', wgc_c);
fprintf('  ZoH half-sample lag (approx): %.1f deg\n', phi_ZoH_approx);
fprintf('  Observed PM loss:             %.1f deg\n', PM_c-PM_d);
fprintf('  Tustin frequency warp:        %.1f -> %.1f rad/s (%.2f%%)\n', ...
        wgc_c, wc_warped, (wc_warped-wgc_c)/wgc_c*100);
fprintf('  --> ZoH half-sample delay explains the bulk of the PM loss;\n');
fprintf('      Tustin warping is negligible at this wc/Nyquist ratio.\n');

%% ---- Step j.3: Retune controller to compensate discretisation loss ---
% Target a higher CONTINUOUS PM so the discretised result lands near 40 deg.
PM_target_cont = 45 + (PM_c - PM_d);
[~,ph_at_wc] = bode(sysem, wc);
phi_needed = PM_target_cont - (180 + ph_at_wc);
if phi_needed <= 0
    alpha_r = delGHI.alpha;
else
    alpha_r = (1-sind(phi_needed))/(1+sind(phi_needed));
    alpha_r = max(0.001, min(0.999, alpha_r));
end

tau_z_r = sqrt(1/alpha_r)/wc;
tau_i_r = beta*tau_z_r;
tau_p_r = 1/(wc*sqrt(1/alpha_r));
kp_r    = m_eq*wc^2/sqrt(1/alpha_r);
C_PID_r = kp_r*(tau_z_r*s_tf+1)*(tau_i_r*s_tf+1)/((tau_p_r*s_tf+1)*tau_i_r*s_tf);

OL_r_cont = C_PID_r * sysem;
Cz_r      = c2d(C_PID_r, ts, 'tustin');
OL_r_disc = Cz_r * Pz_zoh;
CL_r_disc = feedback(OL_r_disc, 1);

[GM_rc,PM_rc,~,wgc_rc] = margin(OL_r_cont);
[GM_rd,PM_rd,wpc_rd,wgc_rd] = margin(OL_r_disc);

fprintf('\n=== Step 3: Retuned controller (target continuous PM=%.1f deg) ===\n', PM_target_cont);
fprintf('  alpha: %.4f -> %.4f\n', delGHI.alpha, alpha_r);
fprintf('  Retuned continuous:  PM=%.1f deg, wc=%.1f rad/s\n', PM_rc, wgc_rc);
fprintf('  Retuned discrete:    PM=%.1f deg, wc=%.1f rad/s, GM=%.1f dB (at %.1f rad/s)\n', ...
        PM_rd, wgc_rd, 20*log10(GM_rd), wpc_rd);

n_unstable_r = sum(abs(pole(CL_r_disc))>1);
if n_unstable_r==0
    fprintf('  Closed-loop STABLE (discrete, retuned alpha)\n');
else
    fprintf('  WARNING: Closed-loop UNSTABLE (discrete, retuned alpha)\n');
end
fprintf('  Note: PM ceiling (~30 deg) is the same fundamental plant limit\n');
fprintf('        identified in deliverable i, not a discretisation artifact.\n');

%% ---- Summary table -----------------------------------------------------
fprintf('\n--- Deliverable j summary table ---\n');
fprintf('%-42s  %8s  %8s  %8s\n','Configuration','wc(rad/s)','PM(deg)','GM(dB)');
fprintf('%-42s  %8.1f  %8.1f  %8.1f\n','Continuous (original alpha)',wgc_c,PM_c,20*log10(GM_c));
fprintf('%-42s  %8.1f  %8.1f  %8.1f\n','Discrete Tustin+ZoH (original alpha)',wgc_d,PM_d,20*log10(GM_d));
fprintf('%-42s  %8.1f  %8.1f  %8.1f\n','Discrete Tustin+ZoH (retuned alpha)',wgc_rd,PM_rd,20*log10(GM_rd));

%% ---- Figure j.1: Continuous vs Discrete OL Bode overlay ---------------
figure('Name','Deliverable j: Continuous vs Discrete OL Bode');
bode(OL_cont, OL_disc, OL_r_disc);
legend('Continuous C*P_{em}', ...
       'Discrete (Tustin C, ZoH P) - original alpha', ...
       'Discrete (Tustin C_{retuned}, ZoH P)', ...
       'Location','southwest');
title('Deliverable j - Effect of discretisation on open-loop frequency response');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

%% ---- Figure j.2: Discrete OL margin plot (retuned) ---------------------
figure('Name','Deliverable j: Discrete OL margin (retuned)');
margin(OL_r_disc);
title('Deliverable j - Discrete open-loop C_z(retuned) cdot P_z(ZoH)');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

%% ---- Figure j.3: Discrete CL pole-zero map -----------------------------
figure('Name','Deliverable j: Discrete CL pole-zero map');
pzmap(CL_disc, CL_r_disc);
zgrid;
legend('Original alpha','Retuned alpha','Location','northwest');
title('Deliverable j - Discrete closed-loop poles (unit circle = stability boundary)');

%% ---- Pack outputs --------------------------------------------------------
delJ.ts        = ts;
delJ.Pz_zoh    = Pz_zoh;
delJ.Cz_tustin = Cz_tustin;
delJ.OL_disc   = OL_disc;
delJ.CL_disc   = CL_disc;
delJ.alpha_orig    = delGHI.alpha;
delJ.alpha_retuned = alpha_r;
delJ.Cz_retuned    = Cz_r;
delJ.OL_retuned    = OL_r_disc;
delJ.CL_retuned    = CL_r_disc;
delJ.PM_cont       = PM_c;
delJ.PM_disc       = PM_d;
delJ.PM_retuned    = PM_rd;
delJ.GM_cont_dB    = 20*log10(GM_c);
delJ.GM_disc_dB    = 20*log10(GM_d);
delJ.GM_retuned_dB = 20*log10(GM_rd);
delJ.wc_cont       = wgc_c;
delJ.wc_disc       = wgc_d;
delJ.wc_retuned    = wgc_rd;
delJ.phase_lag_ZoH_deg = phi_ZoH_approx;

end  % discretization
