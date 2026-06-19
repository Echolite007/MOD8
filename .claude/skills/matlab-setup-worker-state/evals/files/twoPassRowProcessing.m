function [bestPositions, bestScores] = twoPassRowProcessing(costSurfaceFile, bounds, numParticles, numIterations)
%TWOPASSROWPROCESSING Particle swarm style optimization over a cost surface
%   Runs a parallel swarm search over multiple iterations, evaluating
%   particle fitness by interpolating into a precomputed cost surface.
% Copyright 2026 The MathWorks, Inc.

arguments
    costSurfaceFile (1,1) string
    bounds (:,2) double
    numParticles (1,1) double = 50
    numIterations (1,1) double = 10
end

nDims = size(bounds, 1);

% Initialize particle positions randomly within bounds
positions = bounds(:,1)' + (bounds(:,2) - bounds(:,1))' .* rand(numParticles, nDims);
velocities = zeros(numParticles, nDims);
bestPositions = positions;
bestScores = inf(1, numParticles);

globalBestPos = zeros(1, nDims);
globalBestScore = inf;

for iter = 1:numIterations
    % Evaluate all particles in parallel
    scores = zeros(1, numParticles);
    parfor p = 1:numParticles
        data = load(costSurfaceFile, "costSurface");
        scores(p) = evaluateParticle(positions(p, :), data.costSurface, bounds);
    end

    % Update personal and global bests
    improved = scores < bestScores;
    bestScores(improved) = scores(improved);
    bestPositions(improved, :) = positions(improved, :);

    [iterBest, idx] = min(scores);
    if iterBest < globalBestScore
        globalBestScore = iterBest;
        globalBestPos = positions(idx, :);
    end

    % Update velocities and positions in parallel
    parfor p = 1:numParticles
        velocities(p, :) = updateVelocity(velocities(p, :), ...
            positions(p, :), bestPositions(p, :), globalBestPos, bounds); %#ok<PFOUS>
        positions(p, :) = clampPosition(positions(p, :) + velocities(p, :), bounds);
    end
end
end

function score = evaluateParticle(position, costSurface, bounds)
    nDims = numel(position);
    normalized = (position - bounds(:,1)') ./ (bounds(:,2) - bounds(:,1))';
    gridIndices = max(1, min(size(costSurface), round(normalized .* (size(costSurface) - 1)) + 1));
    if nDims >= 2
        score = costSurface(gridIndices(1), gridIndices(2));
    else
        score = costSurface(gridIndices(1), 1);
    end
end

function v = updateVelocity(v, pos, pBest, gBest, bounds)
    inertia = 0.7;
    cognitive = 1.5 * rand(size(v)) .* (pBest - pos);
    social = 1.5 * rand(size(v)) .* (gBest - pos);
    scale = (bounds(:,2) - bounds(:,1))';
    v = inertia * v + cognitive + social;
    v = max(min(v, 0.2*scale), -0.2*scale);
end

function pos = clampPosition(pos, bounds)
    pos = max(min(pos, bounds(:,2)'), bounds(:,1)');
end
