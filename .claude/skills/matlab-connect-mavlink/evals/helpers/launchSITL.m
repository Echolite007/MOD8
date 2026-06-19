function sitl = launchSITL(options)
%launchSITL Launch PX4 SITL via WSL for integration testing.
%
%   sitl = launchSITL() launches PX4 SITL with default settings.
%   sitl = launchSITL(Broadcast=true) enables broadcast mode.
%
%   Returns a struct with fields:
%     process   - Java Process object (for cleanup)
%     host      - WSL IP address (string)
%     port      - SITL UDP listening port (double)
%     ready     - true if SITL started successfully
%
%   Call teardownSITL(sitl) when done.

% Copyright 2026 The MathWorks, Inc.

    arguments
        options.Broadcast (1,1) logical = false
        options.PX4Dir string = "~/px4_16"
        options.MakeTarget string = "px4_sitl_sih sihsim_quadx"
        options.StartupTimeout (1,1) double = 90
    end

    sitl = struct('process', [], 'host', "", 'port', 18570, 'ready', false);

    % Get WSL IP
    [~, output] = system('wsl -e bash -c "hostname -I | awk ''{print $1}''"');
    lines = splitlines(strip(string(output)));
    ipLine = lines(~startsWith(lines, "wsl:") & strlength(lines) > 0);
    if isempty(ipLine)
        warning('launchSITL:noIP', 'Could not determine WSL IP');
        return;
    end
    sitl.host = strip(ipLine(end));

    % Kill any existing SITL
    system('wsl -e bash -c "pkill -f px4 2>/dev/null; sleep 1"');

    % Set broadcast mode
    configPath = options.PX4Dir + "/build/px4_sitl_sih/etc/init.d-posix/px4-rc.mavlink";
    if options.Broadcast
        replacement = "mavlink_network_interface_arg=-p";
    else
        replacement = "mavlink_network_interface_arg=";
    end
    cmd = sprintf('wsl -e bash -c "sed -i ''14s/.*/%s/'' %s"', ...
        replacement, configPath);
    system(cmd);

    % Launch SITL
    buildCmd = sprintf("cd %s && make %s 2>&1", options.PX4Dir, options.MakeTarget);
    pb = java.lang.ProcessBuilder(["wsl", "-e", "bash", "-c", buildCmd]);
    pb.redirectErrorStream(true);
    sitl.process = pb.start();

    reader = java.io.BufferedReader( ...
        java.io.InputStreamReader(sitl.process.getInputStream()));

    % Wait for SITL to be ready
    tic;
    while toc < options.StartupTimeout
        if reader.ready()
            line = string(reader.readLine());
            if contains(line, "udp port") || contains(line, "pxh>")
                sitl.ready = true;
                % Try to extract port from line like "[mavlink] ... on udp port 18570"
                tokens = regexp(line, 'udp port (\d+)', 'tokens');
                if ~isempty(tokens)
                    sitl.port = str2double(tokens{1}{1});
                end
                break;
            end
        else
            pause(0.1);
        end
    end

    if ~sitl.ready
        warning('launchSITL:timeout', 'SITL did not start within %d seconds', ...
            options.StartupTimeout);
        teardownSITL(sitl);
        return;
    end

    pause(2);  % Allow SITL to stabilize
end
