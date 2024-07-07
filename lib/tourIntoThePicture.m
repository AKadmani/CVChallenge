function [surfaces,scale] = tourIntoThePicture(img,vanishing_point,estimatedVertex)
    % tourIntoThePicture Reconstructs 3D surfaces from a 2D image.
    % Inputs:
    %   img             - Input image as a 2D matrix.
    %   vanishing_point - The vanishing point in the image 
    %   estimatedVertex - Estimated 2D vertex coordinates in the image.
    % Outputs:
    %   surfaces        - Reconstructed 3D surfaces.
    %   scale           - Scaling factor for depth information.
    
    % Calculate a scaling factor based on the image size
    scalingFactor = ceil(max(size(img(:,:)))/5);
    
    % Convert 2D vertices to 3D coordinates
    vertex3D = convert2Dto3D(vanishing_point,estimatedVertex);

    % Scale the z-coordinates of the reconstructed vertices
    vertex3D(3,:) = vertex3D(3,:) * scalingFactor;
    
    % Get the 3D surfaces and scale
    [surfaces,scale] = getSurfaces( estimatedVertex, vertex3D, img);

end