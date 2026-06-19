function dataDir = genL6_CSV_D_metadataprelude()
%GENL6_CSV_D_METADATAPRELUDE  Generate CSVs for the L6-CSV-D eval.
%   dataDir = genL6_CSV_D_metadataprelude() creates 30 .csv files in a
%   flat folder. rng(0) is seeded for reproducibility.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L6_CSV_D_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

N = 256;
nFiles = 30;
fsOptions = [250, 500, 1000];
classes = ["ClassA", "ClassB", "ClassC"];
toneHz = [50, 80, 130];

assignments = [];
counts = [15, 9, 6];
for c = 1:numel(classes)
    assignments = [assignments; repmat(c, counts(c), 1)]; %#ok<AGROW>
end
assignments = assignments(randperm(numel(assignments)));

for k = 1:nFiles
    c = assignments(k);
    cls = classes(c);
    f0 = toneHz(c);
    fs = fsOptions(mod(k-1, numel(fsOptions)) + 1);

    t = (0:N-1)' / fs;
    signal = sin(2*pi*f0*t) + 0.3*randn(N,1);

    fname = sprintf('sample_%02d.csv', k);
    fid = fopen(fullfile(dataDir, fname), 'w');
    fprintf(fid, '# fs: %d\n', fs);
    fprintf(fid, '# class: %s\n', cls);
    fprintf(fid, '# nSamples: %d\n', N);
    fprintf(fid, '[Data]\n');
    fprintf(fid, 't,signal\n');
    for i = 1:N
        fprintf(fid, '%.6f,%.6f\n', t(i), signal(i));
    end
    fclose(fid);
end

fprintf('genL6_CSV_D_metadataprelude: %d files in %s\n', nFiles, dataDir);
end

% Copyright 2026 The MathWorks, Inc.
