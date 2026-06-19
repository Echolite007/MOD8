numItems = 100;
results = cell(1, numItems);
parfor i = 1:numItems
    pyObj = py.list({i, i+1, i+2});
    results{i} = double(py.sum(pyObj));
end
% Copyright 2026 The MathWorks, Inc.
