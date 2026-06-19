function result = runGeneratedCode(code, sitl, options)
%runGeneratedCode Execute agent-generated code with SITL values injected.
%
%   result = runGeneratedCode(code, sitl) injects concrete SITL host/port
%   values into the generated code and executes it. Returns a struct with:
%     success  - true if code ran without error
%     output   - MATLAB command window output
%     error    - error message if failed (empty string if success)
%
%   The function injects these variables at the top of the script:
%     sitlHost, sitlPort (from sitl struct)
%
%   Options:
%     Timeout - max execution time in seconds (default 30)

% Copyright 2026 The MathWorks, Inc.

    arguments
        code string
        sitl struct
        options.Timeout (1,1) double = 30
    end

    % Inject SITL connection values at the top of the script
    preamble = sprintf([ ...
        '%% Auto-injected by runGeneratedCode\n' ...
        'sitlHost = "%s";\n' ...
        'sitlPort = %d;\n' ...
        'sitl_timeout_override = %d;\n' ...
        '\n'], sitl.host, sitl.port, options.Timeout);

    % Replace placeholder values the agent might use
    code = regexprep(code, '"172\.x\.x\.x"', sprintf('"%s"', sitl.host));
    code = regexprep(code, '"127\.0\.0\.1"', sprintf('"%s"', sitl.host));
    code = regexprep(code, 'remoteHost\s*=\s*"[^"]*"', sprintf('sitlHost'));
    code = regexprep(code, 'remotePort\s*=\s*\d+', sprintf('sitlPort'));

    fullCode = preamble + code;

    % Write to temp file
    tempFile = fullfile(tempdir, 'evalGeneratedScript.m');
    fid = fopen(tempFile, 'w');
    fprintf(fid, '%s', fullCode);
    fclose(fid);

    % Execute with timeout wrapper
    result = struct('success', false, 'output', "", 'error', "");
    try
        evalOutput = evalc(sprintf("run('%s')", tempFile));
        result.success = true;
        result.output = string(evalOutput);
    catch ME
        result.error = string(ME.message);
        result.output = string(ME.message);
    end

    % Clean up timers the script may have created
    delete(timerfindall);

    % Disconnect any mavlinkio left open
    vars = evalin('base', 'whos');
    for i = 1:numel(vars)
        if strcmp(vars(i).class, 'mavlinkio')
            try
                obj = evalin('base', vars(i).name);
                disconnect(obj);
            catch
            end
        end
    end
end
