%% Large Array Computation with spmd
% Distribute a large matrix operation across local workers.

n = 8000;
m = 200;

spmd
    % Each worker generates its chunk of rows
    numLocalRows = fix(n / spmdSize);
    if spmdIndex <= mod(n, spmdSize)
        numLocalRows = numLocalRows + 1;
    end
    localA = rand(numLocalRows, n);
    B = rand(n, m);
    localC = localA * B;
end

% Gather results back — large data returned from each worker
C = vertcat(localC{:});
fprintf("Result size: %d x %d, sum: %.4f\n", size(C,1), size(C,2), sum(C,"all"));

% Copyright 2026 The MathWorks, Inc.
