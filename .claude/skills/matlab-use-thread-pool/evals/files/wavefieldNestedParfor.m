%% wavefieldNestedParfor
% Edric review Example 2: nested parfor/for over a 3001x3001 grid with
% small broadcast variables. ticBytes shows ~100 MB sent to each worker.
% The skill should recommend parpool("Threads") and note that the broadcast
% spectra are zero-copy on threads -- but should not claim sliced outputs
% are also zero-copy.

ny = 60;
nx = 60;

X = rand(nx, ny);
Y = rand(nx, ny);
spec_dfdt = rand(123, 93);
wnk = rand(123, 93);
wnkcosDir = rand(123, 93);
wnksinDir = rand(123, 93);
romega = rand(123, 93);
gamma = rand(123, 93);
grav = 9.81;

eta = zeros(nx, ny);
u = zeros(nx, ny);
v = zeros(nx, ny);
w = zeros(nx, ny);
deta_dx = zeros(nx, ny);
deta_dy = zeros(nx, ny);

parfor jj = 1:ny
    y = Y(jj);
    for ii = 1:nx
        x = X(ii);

        CosTerm = cos(wnkcosDir*x + wnksinDir*y + gamma);
        SinTerm = sin(wnkcosDir*x + wnksinDir*y + gamma);

        eta(ii,jj)     = sum(sum(spec_dfdt.*CosTerm, 1), 2);
        u(ii,jj)       = grav*sum(sum(wnkcosDir.*spec_dfdt.*CosTerm.*romega, 1), 2);
        v(ii,jj)       = grav*sum(sum(wnksinDir.*spec_dfdt.*CosTerm.*romega, 1), 2);
        w(ii,jj)       = grav*sum(sum(wnk.*spec_dfdt.*SinTerm.*romega, 1), 2);
        deta_dx(ii,jj) = -sum(sum(spec_dfdt.*wnkcosDir.*SinTerm, 1), 2);
        deta_dy(ii,jj) = -sum(sum(spec_dfdt.*wnksinDir.*SinTerm, 1), 2);
    end
end

% Copyright 2026 The MathWorks, Inc.
