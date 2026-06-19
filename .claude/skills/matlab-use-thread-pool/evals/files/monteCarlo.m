%% Monte Carlo Simulation with parfor
% Price multiple options by simulating full path matrices.

numPaths = 50000;
numSteps = 252;
numOptions = 20;

S0 = 100;
r = 0.05;
sigma = 0.2;
T = 1;
dt = T / numSteps;

% Pre-generate random draws — large matrix sent to each iteration
Z = randn(numPaths, numSteps, numOptions);

strikes = linspace(90, 110, numOptions);
prices = zeros(1, numOptions);

parfor k = 1:numOptions
    paths = Z(:,:,k);
    S = S0 * ones(numPaths, 1);
    for t = 1:numSteps
        S = S .* exp((r - 0.5*sigma^2)*dt + sigma*sqrt(dt)*paths(:,t));
    end
    payoffs = max(S - strikes(k), 0);
    prices(k) = exp(-r*T) * mean(payoffs);
end

fprintf("Priced %d options.\n", numOptions);

% Copyright 2026 The MathWorks, Inc.
