function [FGVertex, foreobj] = foregroundObject3D(img, vanishing_point, estimatedVertex)
    % foregroundObject3D Identifies and processes a foreground object within an image.
    % Inputs:
    %   img                 - The input image.
    %   vanishing_point     - The vanishing point in the image
    %   estimatedVertex     - Estimated 2D vertex coordinates in the image.
    % Outputs:
    %   FGVertex            - The 2D vertex coordinates of the foreground object.
    %   foreobj             - The 3D coordinates of the foreground object.

    % Allow user to draw polygon interactively
    roi_poly = drawpolygon('Label', 'Select foreground object');
    
    % Create binary mask from polygon
    roi_mask = createMask(roi_poly);
    
    % Convert polygon mask to coordinates
    [y_roi, x_roi] = find(roi_mask);
    min_y_fore = min(y_roi);
    max_y_fore = max(y_roi);
    min_x_fore = min(x_roi);
    max_x_fore = max(x_roi);

    % Precompute size parameters
    pic_num = ceil(max(size(img(:,:))) / 5);

    % Floor the inputs
    min_y_fore = floor(min_y_fore);
    min_x_fore = floor(min_x_fore);
    max_y_fore = floor(max_y_fore);
    max_x_fore = floor(max_x_fore);

    % 2D coordinates of foreground object
    x_sp_fore = [min_x_fore; max_x_fore; max_x_fore; min_x_fore]';
    y_sp_fore = [max_y_fore; max_y_fore; min_y_fore; min_y_fore]';

    % Vertex coordinates
    FGVertex = [min_x_fore max_x_fore max_x_fore min_x_fore;
                max_y_fore max_y_fore min_y_fore min_y_fore];

    % Initial 2D coordinates
    foreobj = [x_sp_fore; y_sp_fore];

    % Calculate x coordinate using estimatedVertex
    x = estimatedVertex(1, 5) - (estimatedVertex(2, 5) - y_sp_fore(3)) * (estimatedVertex(1, 5) - estimatedVertex(1, 1)) / (estimatedVertex(2, 5) - estimatedVertex(2, 1));
    fore = [x; y_sp_fore(1)];

    % Add z coordinate (3D coordinates)
    foreobj = [foreobj; zeros(1, 4)];

    % Preallocate distances array
    L = zeros(12, 1);

    % Ensure vanishing_point is a row vector
    vanishing_point = vanishing_point(:)';

    % Distance between vanishing point and estimated vertex
    for i = 1:12
        L(i) = pdist([vanishing_point; estimatedVertex(:, i)'], 'euclidean');
    end

    % Distance of vanishing point and foreground point
    K = pdist([vanishing_point; fore'], 'euclidean');

    % Find the z coordinate of the foreground object
    y_ref = max(estimatedVertex(2, 5), estimatedVertex(2, 3));
    y_cut = (y_sp_fore(1) + y_sp_fore(3)) / 2;
    foreobj(3, :) = abs(y_cut - vanishing_point(2)) / abs(y_ref - vanishing_point(2));

    % Apply proportional relationship
    foreobj([1, 2], :) = (foreobj([1, 2], :) - vanishing_point') .* foreobj(3, :);
    foreobj(3, :) = foreobj(3, :) * pic_num;
end