function ref = get_reference_peaks(vw, tw, tr, ts)
% GET_REFERENCE_PEAKS  Run the provided ReferenceGenerator_2023a.slx
% headlessly and extract peak reference values needed for sizing.
%
% The reference generator model is PROVIDED and must not be rewritten
% (CLAUDE.md Sec. 2). This function builds a small throwaway harness
% model in memory, feeds it the requested vw/tw/tr/ts, simulates it,
% and reads off the peak |r|, |dr|, |ddr|, |dddr| and the a2p constant.
% The harness is closed at the end and the .slx file on disk is never
% modified.
%
% Inputs:
%   vw  driving velocity [m/s]
%   tw  weeding time [s]
%   tr  return time [s]
%   ts  sample time [s] used only for the harness's fixed-step solver
%       (fine enough to resolve the true peaks, independent of the
%       controller's eventual discretisation sample time)
%
% Output: struct ref with fields
%   theta_max    [rad]      peak |r|
%   dtheta_max   [rad/s]    peak |dr|
%   ddtheta_max  [rad/s^2]  peak |ddr|
%   dddtheta_max [rad/s^3]  peak |dddr|
%   a2p          [m/rad]    angle-to-spot-position transmission
%   t, r, dr, ddr, dddr     full time series (for plotting / deliverable d)

if nargin < 1 || isempty(vw); error('get_reference_peaks:vw_required','vw must be supplied'); end
if nargin < 2 || isempty(tw); error('get_reference_peaks:tw_required','tw must be supplied'); end
if nargin < 3 || isempty(tr); error('get_reference_peaks:tr_required','tr must be supplied'); end
if nargin < 4 || isempty(ts); ts = 1e-4; end  % fine default just for peak extraction

refgenName = 'ReferenceGenerator_2023a';
harness = 'refgen_harness_tmp';

% Close any stale loaded copies under either name to avoid path clashes
if bdIsLoaded(refgenName); close_system(refgenName, 0); end
if bdIsLoaded(harness);    close_system(harness, 0);    end

load_system([refgenName '.slx']);

new_system(harness);
load_system(harness);

add_block('simulink/Sources/Constant', [harness '/vw_const'], 'Value', num2str(vw, 16));
add_block('simulink/Sources/Constant', [harness '/tw_const'], 'Value', num2str(tw, 16));
add_block('simulink/Sources/Constant', [harness '/tr_const'], 'Value', num2str(tr, 16));
add_block('simulink/Sources/Constant', [harness '/ts_const'], 'Value', num2str(ts, 16));

add_block([refgenName '/Mirror angle for weeding'], [harness '/RefGen']);

outs = {'r','dr','ddr','dddr','a2p'};
for i = 1:numel(outs)
    add_block('simulink/Sinks/To Workspace', [harness '/' outs{i} '_out']);
    set_param([harness '/' outs{i} '_out'], 'VariableName', outs{i});
    set_param([harness '/' outs{i} '_out'], 'SaveFormat', 'Array');
end

add_line(harness, 'vw_const/1', 'RefGen/1');
add_line(harness, 'tw_const/1', 'RefGen/2');
add_line(harness, 'tr_const/1', 'RefGen/3');
add_line(harness, 'ts_const/1', 'RefGen/4');
for i = 1:numel(outs)
    add_line(harness, ['RefGen/' num2str(i)], [outs{i} '_out/1']);
end

set_param(harness, 'StopTime', num2str(tw + tr, 16));
set_param(harness, 'FixedStep', num2str(ts, 16));
set_param(harness, 'SolverType', 'Fixed-step');

simOut = sim(harness);

ref = struct();
ref.t            = simOut.tout;
ref.r            = simOut.r;
ref.dr           = simOut.dr;
ref.ddr          = simOut.ddr;
ref.dddr         = simOut.dddr;
ref.a2p          = simOut.a2p(1);
ref.theta_max    = max(abs(simOut.r));
ref.dtheta_max   = max(abs(simOut.dr));
ref.ddtheta_max  = max(abs(simOut.ddr));
ref.dddtheta_max = max(abs(simOut.dddr));

close_system(harness, 0);
close_system(refgenName, 0);

end
