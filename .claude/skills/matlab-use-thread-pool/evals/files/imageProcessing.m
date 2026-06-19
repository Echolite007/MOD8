%% Image Processing with parfor
% Apply filters to a batch of large images on a local machine.

numImages = 100;
imageSize = 2048;

% Generate synthetic images (large arrays)
images = rand(imageSize, imageSize, numImages);

% Process each image in parallel — each iteration sends and receives a
% full 2048x2048 matrix through the parallel pool.
results = zeros(imageSize, imageSize, numImages);
parfor i = 1:numImages
    img = images(:,:,i);
    filtered = imgaussfilt(img, 2);
    results(:,:,i) = filtered + 0.5*img;
end

fprintf("Processed %d images.\n", numImages);

% Copyright 2026 The MathWorks, Inc.
