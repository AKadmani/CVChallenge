% Navigation3D.m
% Author: Vincent Amberger
% Date: July 01, 2024
% Version: 2.0
% Description: This class creates a 3D room visualization with the ability to move the camera, 
%              change the camera target, and zoom in and out using the mouse and keyboard inputs.


classdef Navigation3D < handle
    properties
         SceneHandle                %Handle to the Scene
         Axis                       %Handle to the Axis 
         currentCameraPosition      %Camera position [x, y, z]
         currentCameraDirection     %Camera direction [x, y, z]
         walls                      %Walls of the 3D-Room -> 5 cellArray
    end
    
    methods
        function obj = Navigation3D(walls)
            % Constructor: Initializes the Navigation3D object
            % Parameters:
            %   walls - Cell array containing the textures for the floor and walls
            obj.walls = walls;
            obj = obj.initializeScene(walls); %Initialize the Scene
            obj.setupCamera();                %Setup the Camera
        end

        function obj = initializeScene(obj, walls)
            [xBack,yBack,~] = size(walls{1});
            [~,y,~] = size(walls{2});
            
            %Starting Position and Direction of the Camera
            %Startingpos -> Middle of the room
            obj.currentCameraPosition = [xBack/2,yBack/2, -y];
            obj.currentCameraDirection = [0, 0, 1];
            
            % Initialize the main window and axes
            obj.SceneHandle = figure('Name', '3D Raum', 'NumberTitle', 'off');
            obj.Axis = axes('Parent', obj.SceneHandle, 'Units', 'normalized', 'Cameraposition', obj.currentCameraPosition);
        
            % Setup callbacks for mouse movement, keyboard press, and mouse scroll
            set(obj.SceneHandle, 'WindowButtonMotionFcn', @obj.mouseMove);
            set(obj.SceneHandle, 'KeyPressFcn', @obj.keypress);
            set(obj.SceneHandle, 'WindowScrollWheelFcn', @obj.mouseWheel);
            
            %Render the 3D scene
            obj = obj.renderWalls(walls);


        end

        function setupCamera(obj)
            % Update the camera settings
            obj.updateCamera()
            camproj(obj.Axis, 'perspective');                                       % set perspective
            camva(obj.Axis, 45);                                                    % set view
        end
        



        function obj = renderWalls(obj, walls)
            % Render 3D surfaces based on input data
            hold(obj.Axis, 'on');

            %Background
            [xBack, yBack, ~] = size(walls{1});
            [X, Y] = meshgrid(1:yBack, 1:xBack);
            Z = zeros(xBack, yBack);
            C = walls{1};
            h1 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h1, 'LineStyle', 'none');
         
  
            % Left Wall
            [x, y, ~] = size(walls{2});
            [Z_left, Y_left] = meshgrid(-y:-1, 1:x);
            X_left = ones(x, y);
            C = walls{2};
            h2 = surface(X_left, Y_left, Z_left, C, 'Parent', obj.Axis);
            set(h2, 'LineStyle', 'none');
            

            % Floor
            [x, y, ~] = size(walls{3});
            [X_floor, Z_floor] = meshgrid(1:y, -x:-1);
            Y_floor = xBack * ones(x, y);
            C = walls{3};
            h3 = surface(X_floor, Y_floor, Z_floor, C, 'Parent', obj.Axis);
            set(h3, 'LineStyle', 'none');
            
            % Right Wall
            [x, y, ~] = size(walls{4});
            [Z, Y] = meshgrid(-y:-1, 1:x);
            X = yBack * ones(x, y);
            C = rot90(walls{4},2);
            h4 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h4, 'LineStyle', 'none');

            % Ceiling
            [x, y, ~] = size(walls{5});
            [X, Z] = meshgrid(1:y, -x:-1);
            Y = ones(x, y);
            C = fliplr(walls{5});
            h5 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h5, 'LineStyle', 'none');

            view(obj.Axis, 3); % 3D Ansicht setzen
            camlight(obj.Axis, 'headlight'); % Beleuchtung hinzufügen
            lighting(obj.Axis, 'gouraud'); % Glatte Beleuchtung

            axis(obj.Axis, 'equal');
            set(obj.Axis, 'XTick', [], 'YTick', [], 'ZTick', []);
            axis(obj.Axis, 'on');
            hold(obj.Axis, 'off');

        end
        
        %update the Camera based ob the new position and direction
        function updateCamera(obj)
            campos(obj.Axis, obj.currentCameraPosition);                                  % set Cameraposition
            camtarget(obj.Axis, obj.currentCameraPosition + obj.currentCameraDirection);  % set cameratarget
            camup(obj.Axis, -[0 1 0]);                                                    % Set camera up direction 
            %  -> necessary because otherwise the 3DRoom would constantly rotate                                                                   
        end



        function renderForeground(obj, image, foregroundObject, foregroundVertex , scale)
            if numel(image) ~= 0
                hold(obj.Axis, 'on');
                % Calculate the geometric transformation using fitgeotform2d
                tform = fitgeotform2d(foregroundVertex', foregroundObject([1,2], :)' / scale, 'projective');

                % Define region of interest based on transformed foreground object
                min_x = min(foregroundVertex(1, :));
                max_x = max(foregroundVertex(1, :));
                min_y = min(foregroundVertex(2, :));
                max_y = max(foregroundVertex(2, :));

                % Create spatial referencing object for cropped image
                p0 = imref2d(size(image(min_y:max_y, min_x:max_x, :)));
                p0.XWorldLimits = p0.XWorldLimits + min_x - 1;
                p0.YWorldLimits = p0.YWorldLimits + min_y - 1;

        
                % Warp the image and alpha mask
                [warpedImage, ~] = imwarp(image(min_y:max_y, min_x:max_x, :), p0, tform);
                [warpedImage, warpedAlpha] = fgTransparency(warpedImage);

            
                % Prepare meshgrid for 3D surface
                [xBack, ~, ~] = size(obj.walls{1});
                [xImage, yImage, ~] = size(warpedImage);
                y_foreground = linspace(foregroundVertex(1, 1), foregroundVertex(1, 2), yImage) / scale;
                x_foreground = linspace(xBack - xImage, xBack, xImage);
                [X, Y] = meshgrid(y_foreground, x_foreground);
                Z = -foregroundObject(end, 1) * ones(xImage, yImage) / scale;
                C = warpedImage;

                % Create the 3D surface
                h = surface(X,Y,Z,C);
                set(h,'LineStyle','none');
                h.AlphaData = warpedAlpha;
                h.FaceAlpha = 'flat';

                hold(obj.Axis, 'off');
            end
        end


        % Mouse movement callback
        function mouseMove(obj, ~, ~)
            

            % Get the current position of the figure
            figPos = obj.SceneHandle.Position;
            % Get the current mouse pointer location relative to the screen
            mousePos = get(0, 'PointerLocation');
            % Calculate the center of the figure in pixels
            figCenter = figPos(1:2) + figPos(3:4) / 2;
            % Calculate the relative mouse position from the figure center
            relMousePos = mousePos - figCenter;
            
            % Calculate rotation angles based on mouse movement -> Scaling
            % by 200 for sensitivity
            rotX = relMousePos(1) / 200; % X-axis rotation
            rotY = relMousePos(2) / 200; % Y-axis rotation

            % Rotation matrices for rotating around the Y-axis (rotX) and X-axis (rotY)
            R_y = [cosd(rotX) 0 sind(rotX); 0 1 0; -sind(rotX) 0 cosd(rotX)];
            R_x = [1 0 0; 0 cosd(rotY) -sind(rotY); 0 sind(rotY) cosd(rotY)];
 
            
            % Compute the new direction vector of the camera
            newDirection = R_y * R_x * obj.currentCameraDirection';
            obj.currentCameraDirection = newDirection';
            
            %update Camera
            obj.updateCamera()

        end


         % Keyboard press callback
        function keypress(obj, ~, event)
            
            % Handle keyboard inputs to move the cameraposition
            % Parameters:
            %   event - Key press event data

            %  Movement sensibility
            stepSize = 10;
            fixedHeight = obj.currentCameraPosition(2);
            switch event.Key
                case 'w' % Move up
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * obj.currentCameraDirection; 
                case 's' % Move down
                    obj.currentCameraPosition = obj.currentCameraPosition - stepSize * obj.currentCameraDirection; 
                case 'a' % Move left
                    direction = cross(obj.currentCameraDirection, [0, 1, 0]);      %direction vector perpendicular to the cameradirection                
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * direction;
                case 'd' % Move right
                    direction = cross([0, 1, 0], obj.currentCameraDirection);      %direction vector perpendicular to the cameradirection
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * direction;
            end

            % Keep camera height constant
            obj.currentCameraPosition(2) = fixedHeight; 
            
            %Update Camera
            obj.updateCamera();
        end


        % Handle mouse wheel scroll to zoom in and out
        function mouseWheel(obj, ~,event)
            obj.Axis = gca;         %Current Axes
            zoomFactor = 1.1;       %Zoom Factor
            if event.VerticalScrollCount > 0
                % Zoom out
                camzoom(obj.Axis, 1/zoomFactor);
            elseif event.VerticalScrollCount < 0
                % Zoom in
                camzoom(obj.Axis, zoomFactor);
            end
        end
    end
end

 
