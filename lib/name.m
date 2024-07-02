function [out, test] = name(estimatedVertex, recVertex, img)
    [m, n, p] = size(img);
    test = max(max(recVertex([1,2],:)') - min(recVertex([1,2],:)'))/1000;
    test = max(test, 1);

    % Preallocate the output cell array
    out = cell(1, 5);

    % Precompute common values
    recVertexScaled = recVertex / test;

    % Define the vertex indices for each transformation
    vertexIndices = {[1,2,8,7], [11,5,1,7], [1,3,4,2], [2,8,12,6], [7,8,10,9]};

    % Use parallel processing if available
    if license('test', 'Distrib_Computing_Toolbox')
        parfor i = 1:5
            out{i} = processPlane(img, estimatedVertex, recVertexScaled, vertexIndices{i}, i);
        end
    else
        for i = 1:5
            out{i} = processPlane(img, estimatedVertex, recVertexScaled, vertexIndices{i}, i);
        end
    end
end

function outputImage = processPlane(img, estimatedVertex, recVertexScaled, vertexIdx, planeNum)
    % Extract relevant vertices
    estVert = estimatedVertex(:, vertexIdx)';
    recVert = recVertexScaled([1,2], vertexIdx)';

    % Adjust recVert based on plane number
    if planeNum == 2
        recVert = [recVertexScaled([3,2], vertexIdx)'];
    elseif planeNum == 3
        recVert = [recVertexScaled([1,3], vertexIdx)'];
    elseif planeNum == 4
        recVert = [-recVertexScaled([3,2], vertexIdx)'];
    elseif planeNum == 5
        recVert = [-recVertexScaled([1,3], vertexIdx)'];
    end

    % Compute transformation
    tform = fitgeotrans(estVert, recVert, 'projective');

    % Determine region of interest
    minX = floor(min(estVert(:,1)));
    maxX = ceil(max(estVert(:,1)));
    minY = floor(min(estVert(:,2)));
    maxY = ceil(max(estVert(:,2)));

    % Extract relevant portion of image
    if planeNum == 2 || planeNum == 4
        roiImg = img(:, minX:maxX, :);
        p0 = imref2d(size(roiImg));
        p0.XWorldLimits = p0.XWorldLimits + minX - 1;
    else
        roiImg = img(minY:maxY, :, :);
        p0 = imref2d(size(roiImg));
        p0.YWorldLimits = p0.YWorldLimits + minY - 1;
    end

    % Apply transformation
    [warpedImg, p1] = imwarp(roiImg, p0, tform);

    % Compute coordinates for cropping
    vec = [p1.XWorldLimits(1), p1.YWorldLimits(1)];
    coord = ceil(recVert - vec);

    % Crop the warped image
    outputImage = warpedImg(min(coord(:,2)):max(coord(:,2)), min(coord(:,1)):max(coord(:,1)), :);
end