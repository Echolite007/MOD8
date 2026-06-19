%% parforTrigSum
% Edric review Example 3: simple parfor over scalar trig sums. User reports
% parfor on a process pool is only slightly faster than serial for. The
% skill should recommend parpool("Threads") -- threads have negligible
% startup compared to a process pool for tiny workloads.

A = zeros(1, 30);
parfor i = 1:30
    res = 0;
    for n = 1:3000000
        res = res + sin(n) + cos(n);
    end
    A(i) = res;
end

% Copyright 2026 The MathWorks, Inc.
