function [foreground, img] = maskBackground(img, min_y_fore, max_y_fore, min_x_fore, max_x_fore)
    % Preallocate foreground
    foreground = zeros(size(img), 'like', img);
      
    % Use fewer superpixels for faster processing
    numSuperpixels = 300;  % Reduced from 500
    L = superpixels(img, numSuperpixels);
    
    % Create ROI mask more efficiently
    [m, n, ~] = size(img);
    [X, Y] = meshgrid(1:n, 1:m);
    roi = inpolygon(X, Y, [min_x_fore, max_x_fore, max_x_fore, min_x_fore], ...
                         [min_y_fore, min_y_fore, max_y_fore, max_y_fore]);
    
    BW = grabcut(img, L, roi);
    
    % Use logical indexing for efficiency
    foreground_mask = repmat(BW, [1 1 3]);
    foreground(foreground_mask) = img(foreground_mask);
    
    % Inpaint background
    img(foreground_mask) = 0;
    img = inpaintExemplar(img, BW, 'FillOrder', 'tensor');
end
