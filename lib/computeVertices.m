function [vertex] = computeVertices(vanishing_point, rearRectangle, sizeX, sizeY)
    % computeVertices Calculates the 2D coordinates of 12 vertices.
    % Inputs:
    %   vanishing_point - The vanishing point in the image 
    %   rearRectangle   - Corner Coordinates of the inner rectangle.
    %   sizeX           - Width of the image.
    %   sizeY           - Height of the image.
    % Output:
    %   vertex          - Calculated vertices coordinates.

    % Extract the vanishing point coordinates
    y_vp = vanishing_point(1);
    x_vp = vanishing_point(2);
    
    %Calculate gradient
    % Initialize the gradient array to store the slopes
    gradient = zeros(1,4);
    % Calculate gradients for the lines connecting the vanishing point to each of the corners 
    for i =1:4
        gradient(i) = (rearRectangle(i,2)-y_vp)/(rearRectangle(i,1)-x_vp);
    end

    % Initialize the vertex array to store the coordinates
    vertex = zeros(2,12);

    % Assign the known 2D coordinates to their respective positions in the vertex array
    vertex(:,1) = rearRectangle(1,:);
    vertex(:,2) = rearRectangle(2,:);
    vertex(:,8) = rearRectangle(3,:);
    vertex(:,7) = rearRectangle(4,:);
    
    % Calculate the remaining vertices 
    %Radialline 1 
    vertex(:,3) = [(sizeY-y_vp)/gradient(1) + x_vp; sizeY];
    vertex(:,5) = [1; (1-x_vp)*gradient(1) + y_vp];

    %Radialline 2 
    vertex(:,4) = [(sizeY-y_vp)/gradient(2) + x_vp; sizeY];
    vertex(:,6) = [sizeX; (sizeX-x_vp)*gradient(2) + y_vp];

    %Radialline 3 
    vertex(:,10) = [(1-y_vp)/gradient(3) + x_vp; 1];
    vertex(:,12) = [sizeX; (sizeX-x_vp)*gradient(3) + y_vp];
    
    %Radialline 4 
    vertex(:,9) = [(1-y_vp)/gradient(4) + x_vp; 1];
    vertex(:,11) = [1; (1-x_vp)*gradient(4) + y_vp];

end