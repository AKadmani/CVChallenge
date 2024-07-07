function recVertex = convert2Dto3D(vanishing_point,estimatedVertex)
    % convert2Dto3D Converts 2D coordinates to 3D coordinates.
    % Inputs:
    %   vanishing_point - The vanishing point in the image.
    %   estimatedVertex - Estimated 2D vertex coordinates in the image.
    % Output:
    %   recVertex       - Reconstructed 3D coordinates of vertices.
    
    % Initialize the 3D vertex array with the given 2D vertices
    recVertex=[estimatedVertex;zeros(1,12)];

    % Initialize an array to store the Euclidean distances
    distance=zeros(12,1);

    % Calculate Euclidean distances from the vanishing point to each vertex
    for i=1:12
       distance(i)=pdist([[vanishing_point(2),vanishing_point(1)]',estimatedVertex(:,i)]','euclidean');
    end
    
    % Set the z-coordinate of the vertices
    %Radialline 1
    recVertex(3,5)=1;                                                  
    recVertex(3,3)=distance(5)/distance(3);

    %Inner rectangle -> Same distance
    recVertex(3,[1,2,7,8])=distance(5)/distance(1);   

    %Radialline 2
    recVertex(3,4)=distance(2)/distance(4)*distance(5)/distance(1);
    recVertex(3,6)=distance(2)/distance(6)*distance(5)/distance(1);

    %Radialline 3
    recVertex(3,9)=distance(7)/distance(9)*distance(5)/distance(1);
    recVertex(3,11)=distance(7)/distance(11)*distance(5)/distance(1);

    %Radialline 4
    recVertex(3,12)=distance(8)/distance(12)*distance(5)/distance(1);
    recVertex(3,10)=distance(8)/distance(10)*distance(5)/distance(1);
    
    % Adjust the x and y coordinates of the vertices based on the vanishing point and their depths
    recVertex([1,2],:)=(recVertex([1,2],:)-[vanishing_point(2),vanishing_point(1)]').*recVertex(3,:);
end