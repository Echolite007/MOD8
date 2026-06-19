function teardownSITL(sitl)
%teardownSITL Clean up PX4 SITL process launched by launchSITL.
%
%   teardownSITL(sitl) destroys the SITL process and kills any remaining
%   PX4 processes in WSL. Also cleans up any orphaned MATLAB timers.

% Copyright 2026 The MathWorks, Inc.

    arguments
        sitl struct
    end

    % Kill Java process
    if ~isempty(sitl.process) && sitl.process.isAlive()
        sitl.process.destroyForcibly();
        pause(1);
    end

    % Safety net: kill via pkill
    system('wsl -e bash -c "pkill -f px4 2>/dev/null"');

    % Clean up orphaned timers
    delete(timerfindall);
end
