function delGHI = spacarModel(p, delB, delD)
% SPACARMODEL  Deliverables g, h, i: Spacar model, actuator dynamics, PID design.
%
% Inputs:  p (system_parameters), delB (nominal sizing), delD (controller sizing)
% Output:  delGHI struct with all plant models and controller

%% ---- Section 1: Geometry (from deliverable f) -------------------------
w=15; t=0.2; emod=200; Lspring=88; Ld=Lspring*sind(45);
Lxx=364512.64e-9; Lxy=6298.21e-9;  Lxz=-30369.95e-9;
Lyy=662464.35e-9; Lyz=-1381.26e-9; Lzz=884574.96e-9;

%% ---- Section 2: Nodes (mm -> m) ---------------------------------------
nodes = 1e-3 * [
     0         w*1.5625    0      ;  % 1  fixed - flexure 1 base
     Ld        w*1.5625    Ld     ;  % 2  free  - flexure 1 tip
     0         w*10.9375   0      ;  % 3  fixed - flexure 2 base
     Ld        w*10.9375   Ld     ;  % 4  free  - flexure 2 tip
     0         w*6.25      Ld     ;  % 5
     Ld        w*6.25      0      ;  % 6  fixed - frame reference
     Ld        w*6.25      Ld     ;  % 7
     87.56     93.66       Ld     ;  % 8  actuator node
     37.30     93.37       64.88  ;  % 9  mirror CoM
     Ld/2      w*6.25      Ld/2   ;  % 10
    -31.26     86.17       79.51 ];  % 11 sensor node

%% ---- Section 3: Elements ----------------------------------------------
elements = [1 2;3 4;5 6;7 5;2 7;4 7;8 7;9 7;10 7;5 11];

%% ---- Section 4: Node properties ---------------------------------------
clear nprops
nprops(1).fix=true; nprops(3).fix=true; nprops(6).fix=true;
nprops(9).mass=0.247;
nprops(9).mominertia=[Lxx Lxy Lxz Lyy Lyz Lzz];
% Spacar orders outputs by node number: node 8 < node 11
% => output 1 = VCM velocity (node 8), output 2 = sensor pos (node 11)
nprops(8).transfer_in  = 'force_z';
nprops(8).transfer_out = 'veloc_z';   % output 1: VCM velocity
nprops(11).transfer_out= 'displ_x';   % output 2: sensor position
i_sensor=2; j_veloc=1;  % confirmed from slope analysis

%% ---- Section 5: Element properties ------------------------------------
clear eprops
eprops(1).elems=[1 2]; eprops(1).emod=emod*1e9; eprops(1).smod=79e9;
eprops(1).dens=7800; eprops(1).cshape='rect'; eprops(1).dim=[w*3.125e-3 t*1e-3];
eprops(1).orien=[0 1 0]; eprops(1).nbeams=1; eprops(1).flex=1:6;
eprops(1).color='grey'; eprops(1).opacity=0.7; eprops(1).warping=true;

eprops(2).elems=[3]; eprops(2).emod=emod*1e9; eprops(2).smod=79e9;
eprops(2).dens=7800; eprops(2).cshape='rect'; eprops(2).dim=[w*6.25e-3 t*1e-3];
eprops(2).orien=[0 1 0]; eprops(2).nbeams=1; eprops(2).flex=1:6;
eprops(2).color='grey'; eprops(2).opacity=0.7; eprops(2).warping=true;

eprops(3).elems=[4]; eprops(3).cshape='rect'; eprops(3).dim=[w*12.5e-3 0.6e-3];
eprops(3).orien=[0 1 0]; eprops(3).nbeams=1;
eprops(3).color='darkblue'; eprops(3).warping=true;

eprops(4).elems=[5 6 7 8 9 10]; eprops(4).orien=[1 0 0];

%% ---- Section 6: Run Spacar (deliverable g) ----------------------------
opt.gravity=[0 -9.81 0];
opt.transfer={true, p.ctrl.ts_s};
out=spacarlight(nodes,elements,nprops,eprops,opt);
freq=out.step(end).freq;
sysm=out.statespace;

fprintf('\n=== Deliverable g: six lowest eigenfrequencies ===\n');
for k=1:min(6,length(freq))
    fprintf('  Mode %d: %8.2f Hz  (%8.1f rad/s)\n',k,freq(k),freq(k)*2*pi);
end
fprintf('  delB wn (max): %.2f Hz (%.1f rad/s)\n',delB.wn_rad_s/(2*pi),delB.wn_rad_s);

figure('Name','Deliverable g: Mechanical FRF (force to sensor)');
bodeplot(sysm(i_sensor,1));
title('Deliverable g - Mechanical plant: actuator force -> sensor displacement');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

%% ---- Section 7: Actuator dynamics (deliverable h) ---------------------
L_coil=p.actuator.Lcoil_H; R_coil=p.actuator.R25_ohm; km=p.actuator.Kf_N_per_A;
syse  = tf(1,[L_coil R_coil]);
sysem = sysm * km * syse;
sysem = feedback(sysem, km, 1, j_veloc);
sysem = -sysem(i_sensor,1);   % sensor only; flip sign (geometry convention)
sysem = tf(sysem);

fprintf('\n=== Deliverable h: electrical pole at %.1f rad/s (%.1f Hz) ===\n',R_coil/L_coil,R_coil/L_coil/(2*pi));

figure('Name','Deliverable h: Plant with/without actuator dynamics');
bodeplot(-tf(sysm(i_sensor,1)), sysem);
legend('Without actuator dynamics','With actuator dynamics');
title('Deliverable h - Voltage/Force -> sensor displacement');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

%% ---- Section 8: freqsep model reduction --------------------------------
wsplit=freq(1)*1.5*2*pi;
[sys_slow,~]=freqsep(sysem,wsplit);
sys_slow=tf(sys_slow);

figure('Name','Deliverable h: Model reduction via freqsep');
bode(sysem,sys_slow);
legend('Full electromechanical plant','2nd-order approximation (freqsep)');
title('Deliverable h - Model reduction via freqsep');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

%% ---- Section 9: Extract m_eq ------------------------------------------
[num_s,den_s]=tfdata(sys_slow,'v');
m_eq      = abs(den_s(end-2)/num_s(end));
wn_spacar = sqrt(den_s(end));
zeta_fit  = den_s(end-1)/(2*wn_spacar);

fprintf('\n=== Spacar 2nd-order fit ===\n');
fprintf('  wn   = %.2f rad/s (%.2f Hz)\n',wn_spacar,wn_spacar/(2*pi));
fprintf('  zeta = %.4f\n',zeta_fit);
fprintf('  m_eq = %.4g\n',m_eq);

%% =========================================================
%% Deliverable i: effect of parasitic + actuator dynamics
%% on stability margins, and retuning
%% =========================================================

% ---- Step i.1: Nominal plant + nominal controller (baseline, no Spacar) ---
% This is the design as it existed after deliverable d:
% P_nom = (r_arm*km/R) / (J*s^2 + d*s + k_eq),  C from delD.B
s_tf = tf('s');
P_nom_i = (delB.r_arm_m*p.actuator.Kf_N_per_A/p.actuator.R25_ohm) / ...
          (delB.J_kgm2*s_tf^2 + delB.d_Nms_per_rad*s_tf + delB.k_Nm_per_rad);

wc_nom  = delD.B.wc_rad_s;
alpha_nom = delD.alpha;
beta_nom  = delD.beta;
C_nom = build_pid(delB.J_kgm2 / (delB.r_arm_m*p.actuator.Kf_N_per_A/p.actuator.R25_ohm), ...
                  wc_nom, alpha_nom, beta_nom, s_tf);
OL_nom = C_nom * P_nom_i;
[GM_nom,PM_nom,wpc_nom,wgc_nom] = margin(OL_nom);
fprintf('\n=== Deliverable i: stability margin progression ===\n');
fprintf('Step 1 - Nominal plant (delB) + nominal C (delD):\n');
fprintf('  wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB\n',wgc_nom,PM_nom,20*log10(GM_nom));

% ---- Step i.2: Spacar mechanical plant (parasitics) + same C_nom ----------
% Replace P_nom with the full Spacar mechanical plant sysm(i_sensor,1).
% This isolates the effect of parasitic modes, before actuator dynamics.
P_spacar_mech = -tf(sysm(i_sensor,1));  % sign-flipped to positive
OL_mech = C_nom * P_spacar_mech;
[GM_mech,PM_mech,wpc_mech,wgc_mech] = margin(OL_mech);
fprintf('Step 2 - Spacar mechanical plant + same C_nom (parasitic effect):\n');
fprintf('  wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB\n',wgc_mech,PM_mech,20*log10(GM_mech));

% ---- Step i.3: Full electromechanical plant (sysem) + same C_nom ----------
% Now add actuator dynamics on top of parasitics.
OL_em = C_nom * sysem;
[GM_em,PM_em,wpc_em,wgc_em] = margin(OL_em);
fprintf('Step 3 - Full sysem (parasitics + actuator) + same C_nom:\n');
fprintf('  wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB\n',wgc_em,PM_em,20*log10(GM_em));

% ---- Step i.4: Retuned controller at wc_target = p.ctrl.wc_rads ----------
wc_target = p.ctrl.wc_rads;  % 628 rad/s = 100 Hz = Nyquist/10
beta      = delD.beta;
[~,ph_at_wc] = bode(sysem, wc_target);
phi_lead_needed = 45 - (180 + ph_at_wc);
if phi_lead_needed <= 0
    alpha = delD.alpha;
    
else
    alpha = (1-sind(phi_lead_needed))/(1+sind(phi_lead_needed));
    alpha = max(0.001, min(0.999, alpha));
end
C_PID = build_pid(m_eq, wc_target, alpha, beta, s_tf);
OL    = C_PID * sysem;
CL    = feedback(OL, 1);
[GM_val,PM_act,wpc,wgc] = margin(OL);
GM_dB = 20*log10(GM_val);
fprintf('Step 4 - Retuned C_PID on sysem (wc_target=%.0f rad/s):\n',wc_target);
fprintf('  wc=%.1f rad/s, PM=%.1f deg, GM=%.1f dB\n',wgc,PM_act,GM_dB);
if sum(real(pole(CL))>0)==0
    fprintf('  Closed-loop STABLE\n');
else
    fprintf('  WARNING: Closed-loop UNSTABLE\n');
end

% Summary table
fprintf('\n--- Summary table ---\n');
fprintf('%-45s  %8s  %8s  %8s\n','Configuration','wc(rad/s)','PM(deg)','GM(dB)');
fprintf('%-45s  %8.1f  %8.1f  %8.1f\n','Nominal plant + C_nom',wgc_nom,PM_nom,20*log10(GM_nom));
fprintf('%-45s  %8.1f  %8.1f  %8.1f\n','Spacar mech + C_nom (parasitics)',wgc_mech,PM_mech,20*log10(GM_mech));
fprintf('%-45s  %8.1f  %8.1f  %8.1f\n','sysem + C_nom (parasitics+actuator)',wgc_em,PM_em,20*log10(GM_em));
fprintf('%-45s  %8.1f  %8.1f  %8.1f\n','sysem + C_retuned (final)',wgc,PM_act,GM_dB);

% ---- Figure i.1: four-way OL Bode overlay ------------------------------
figure('Name','Deliverable i: Open-loop Bode - before and after');
bode(OL_nom, OL_mech, OL_em, OL);
legend('Nominal plant + C_{nom}  (baseline)', ...
       'Spacar mech + C_{nom}   (+ parasitics)', ...
       'sysem + C_{nom}         (+ actuator dyn.)', ...
       'sysem + C_{retuned}     (final)', ...
       'Location','southwest');
title('Deliverable i - Effect of parasitic and actuator dynamics on open-loop margins');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

% ---- Figure i.2: final OL Bode with margin markers --------------------
figure('Name','Deliverable i: Retuned open-loop Bode (with margins)');
margin(OL);
title('Deliverable i - Retuned open-loop: C_{PID} cdot P_{em}');
grid on; set(findall(gcf,'Type','line'),'LineWidth',1.3);

fprintf('\n=== Retuned PID parameters ===\n');
fprintf('  alpha  = %.4f\n',alpha);
fprintf('  beta   = %.1f\n',beta);
tau_z_r = sqrt(1/alpha)/wc_target;
fprintf('  kp     = %.4g\n',m_eq*wc_target^2/sqrt(1/alpha));
fprintf('  tau_z  = %.4g s  (zero at %.1f rad/s)\n',tau_z_r,1/tau_z_r);
fprintf('  tau_i  = %.4g s  (zero at %.1f rad/s)\n',beta*tau_z_r,1/(beta*tau_z_r));
fprintf('  tau_p  = %.4g s  (pole at %.1f rad/s)\n',1/(wc_target*sqrt(1/alpha)),wc_target*sqrt(1/alpha));

%% ---- Section 11: Pack outputs -----------------------------------------
delGHI.freq      = freq;
delGHI.sysm      = sysm;
delGHI.sysem     = sysem;
delGHI.sys_slow  = sys_slow;
delGHI.m_eq      = m_eq;
delGHI.wn_rad_s  = wn_spacar;
delGHI.zeta      = zeta_fit;
delGHI.C_nom     = C_nom;
delGHI.C_PID     = C_PID;
delGHI.OL_nom    = OL_nom;
delGHI.OL_mech   = OL_mech;
delGHI.OL_em     = OL_em;
delGHI.OL        = OL;
delGHI.CL        = CL;
delGHI.wc_rad_s  = wgc;
delGHI.wc_target = wc_target;
delGHI.PM_deg    = PM_act;
delGHI.GM_dB     = GM_dB;
delGHI.alpha     = alpha;
delGHI.beta      = beta;
delGHI.PM_nom    = PM_nom;
delGHI.PM_mech   = PM_mech;
delGHI.PM_em     = PM_em;

end  % spacarModel

% ---- Local helper: build PID + lead TF ---------------------------------
function C = build_pid(m_eq, wc, alpha, beta, s)
% C(s) = kp*(tau_z*s+1)*(tau_i*s+1) / [(tau_p*s+1)*tau_i*s]
tau_z = sqrt(1/alpha)/wc;
tau_i = beta*tau_z;
tau_p = 1/(wc*sqrt(1/alpha));
kp    = m_eq*wc^2/sqrt(1/alpha);
C = kp*(tau_z*s+1)*(tau_i*s+1)/((tau_p*s+1)*tau_i*s);
end
