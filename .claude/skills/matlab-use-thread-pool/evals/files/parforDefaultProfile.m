%% parforDefaultProfile
% Numeric parfor used as the eval input for the "make threads my default"
% prompt. The point of the eval is the persistent-profile recommendation,
% not the loop body.

n = 200;
results = zeros(1, n);
parfor ii = 1:n
    x = rand(1000, 1000);
    results(ii) = sum(x, "all") / numel(x);
end

% Copyright 2026 The MathWorks, Inc.
