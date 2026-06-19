function [ready, diagnostics] = checkSITLPrerequisites()
%checkSITLPrerequisites Verify platform can run PX4 SITL integration tests.
%
%   [ready, diagnostics] = checkSITLPrerequisites() returns true if:
%     1. Running on Windows
%     2. WSL is available and responsive
%     3. PX4 source tree exists at ~/px4_16 in WSL
%     4. UAV Toolbox is installed
%
%   diagnostics is a struct with fields:
%     isWindows, hasWSL, hasPX4, hasUAVToolbox, wslIP, messages

% Copyright 2026 The MathWorks, Inc.

    diagnostics = struct( ...
        'isWindows', false, ...
        'hasWSL', false, ...
        'hasPX4', false, ...
        'hasUAVToolbox', false, ...
        'wslIP', "", ...
        'messages', strings(0));

    % Check 1: Windows platform
    diagnostics.isWindows = ispc;
    if ~diagnostics.isWindows
        diagnostics.messages(end+1) = "Not running on Windows — SITL tests require WSL";
        ready = false;
        return;
    end

    % Check 2: WSL available
    [status, ~] = system('wsl --status 2>&1');
    diagnostics.hasWSL = (status == 0);
    if ~diagnostics.hasWSL
        diagnostics.messages(end+1) = "WSL not available or not responding";
        ready = false;
        return;
    end

    % Check 3: PX4 source tree
    [status, ~] = system('wsl -e bash -c "test -d ~/px4_16 && echo ok"');
    diagnostics.hasPX4 = (status == 0);
    if ~diagnostics.hasPX4
        diagnostics.messages(end+1) = "PX4 source not found at ~/px4_16 in WSL";
        ready = false;
        return;
    end

    % Check 4: UAV Toolbox
    tbInfo = ver('uav');
    diagnostics.hasUAVToolbox = ~isempty(tbInfo);
    if ~diagnostics.hasUAVToolbox
        diagnostics.messages(end+1) = "UAV Toolbox not installed";
        ready = false;
        return;
    end

    % Get WSL IP for SITL connection
    [~, output] = system('wsl -e bash -c "hostname -I | awk ''{print $1}''"');
    lines = splitlines(strip(string(output)));
    ipLine = lines(~startsWith(lines, "wsl:") & strlength(lines) > 0);
    if ~isempty(ipLine)
        diagnostics.wslIP = strip(ipLine(end));
    end

    diagnostics.messages(end+1) = "All prerequisites met";
    ready = true;
end
