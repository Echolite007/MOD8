function results = parallelQueryFetch(queries)
%PARALLELQUERYFETCH Fetch query results using a parallel pool
% Copyright 2026 The MathWorks, Inc.

results = cell(1, numel(queries));
parfor i = 1:numel(queries)
    conn = database("MyDB", "user", "pass");
    results{i} = fetch(conn, queries{i});
    close(conn);
end
end
