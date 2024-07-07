function [foreground, img] = extractForeground(img, min_y_fore, max_y_fore, min_x_fore, max_x_fore)
    % extractForeground Masks the background in an image using foreground segmentation.
    % Inputs:
    %   img                                             - The input image 
    %   min_y_fore, max_y_fore, min_x_fore, max_x_fore  - Bounding box coordinates for the foreground
    % Outputs:
    %   foreground                                      - The segmented foreground image
    %   img                                             - The inpainted background image

    % Preallocate foreground
    foreground = zeros(size(img), 'like', img);

    % Use fewer superpixels for faster processing
    numSuperpixels = 300;
    L = superpixels(img, numSuperpixels);

    % Create ROI mask more efficiently
    [m, n, ~] = size(img);
    [X, Y] = meshgrid(1:n, 1:m);
    roi = inpolygon(X, Y, [min_x_fore, max_x_fore, max_x_fore, min_x_fore], ...
                    [min_y_fore, min_y_fore, max_y_fore, max_y_fore]);

    % Use GrabCut to refine foreground/background segmentation
    BW = grabcut(img, L, roi);

    % Use logical indexing for efficiency
    foreground_mask = repmat(BW, [1 1 3]);
    foreground(foreground_mask) = img(foreground_mask);

    % Inpaint background
    img(foreground_mask) = 0;
    img = inpaintExemplar(img, BW, 'FillOrder', 'tensor');
end