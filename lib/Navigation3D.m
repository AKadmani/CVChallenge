classdef Navigation3D < handle
    properties
         SceneHandle
         Axis
         currentCameraPosition
         currentCameraDirection
         midPoint
    end
    
    methods
        function obj = Navigation3D(walls)
            % Constructor
            obj = obj.initializeScene(walls);
            obj.setupCamera();
        end

        function obj = initializeScene(obj, walls)
            [xBack,yBack,~] = size(walls{1});
            [xFloor,yFloor,zFloor] = size(walls{2});

            obj.currentCameraPosition = [xBack/2,yBack/2, -yFloor];
            obj.currentCameraDirection = [0, 0, 1];

            obj.SceneHandle = figure('Name', '3D Raum', 'NumberTitle', 'off');
            obj.Axis = axes('Parent', obj.SceneHandle, 'Units', 'normalized', 'Cameraposition', [xBack/2,yBack/2, -xFloor/2]);
        
            % Setup callbacks for mouse movement, keyboard press, and mouse scroll
            set(obj.SceneHandle, 'WindowButtonMotionFcn', @obj.mouseMove);
            set(obj.SceneHandle, 'KeyPressFcn', @obj.keypress);
            set(obj.SceneHandle, 'WindowScrollWheelFcn', @obj.mouseWheel);


            % Bildschirmzentrum setzen
            screenCenter = get(0, 'ScreenSize');
            screenCenter = screenCenter(3:4) ./ 2;
            set(0, 'PointerLocation', screenCenter);



            obj = obj.renderWalls(walls);

            obj.Axis.CameraViewAngle = 90;
            camproj(obj.Axis, 'perspective'); % Standardprojektion setzen
            campos(obj.Axis, obj.midPoint); % Kamera-Position setzen
            camtarget(obj.Axis, [obj.midPoint(1), obj.midPoint(2), 0]); % Kamera-Ziel setzen
            camva(obj.Axis, 45); % Setzt den Blickwinkel der Kamera

            obj.Axis.Projection = 'perspective';
            campos( obj.currentCameraPosition )


        end

        function setupCamera(obj)
            % Setup initial camera position and target
            campos(obj.Axis, obj.currentCameraPosition);
            camtarget(obj.Axis, obj.currentCameraPosition + obj.currentCameraDirection);
            camup(obj.Axis, -[0 1 0]); % Set camera up direction
        end
        



        function obj = renderWalls(obj, walls)
            % Render 3D surfaces based on input data
            hold(obj.Axis, 'on');
            
            % Bodenfläche
            [m, n, ~] = size(walls{1});
            [X, Y] = meshgrid(1:n, 1:m);
            Z = zeros(m, n);
            C = walls{1};
            h1 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h1, 'LineStyle', 'none');
        
            % Linke Wand
            [m, n, ~] = size(walls{2});
            [Z, Y] = meshgrid(-n:-1, 1:m);
            X = ones(m, n);
            C = walls{2};
            h2 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h2, 'LineStyle', 'none');
        
            % Hintere Wand
            [m, n, ~] = size(walls{3});
            [m1, ~, ~] = size(walls{1});
            [X, Z] = meshgrid(1:n, -m:-1);
            Y = m1 * ones(m, n);
            C = walls{3};
            h3 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h3, 'LineStyle', 'none');
        
            % Rechte Wand
            [m, n, ~] = size(walls{4});
            [~, n1, ~] = size(walls{1});
            [Z, Y] = meshgrid(-n:-1, 1:m);
            X = n1 * ones(m, n);
            C = fliplr(walls{4});
            h4 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h4, 'LineStyle', 'none');
        
            % Vorderwand
            [m, n, ~] = size(walls{5});
            [m1, ~, ~] = size(walls{1});
            [X, Z] = meshgrid(1:n, -m:-1);
            Y = ones(m, n);
            C = fliplr(walls{5});
            h5 = surface(X, Y, Z, C, 'Parent', obj.Axis);
            set(h5, 'LineStyle', 'none');

            view(obj.Axis, 3); % 3D Ansicht setzen
            camlight(obj.Axis, 'headlight'); % Beleuchtung hinzufügen
            lighting(obj.Axis, 'gouraud'); % Glatte Beleuchtung

            axis(obj.Axis, 'equal');
            set(obj.Axis, 'XTick', [], 'YTick', [], 'ZTick', []);
            axis(obj.Axis, 'off');
            hold(obj.Axis, 'off');

            obj.midPoint = [n1/2, m/2, -n/2];

        end

        function mouseMove(obj, ~, ~)
            % Mouse movement callback
            figPos = obj.SceneHandle.Position;
            mousePos = get(0, 'PointerLocation');
            figCenter = figPos(1:2) + figPos(3:4) / 2;
            
            relMousePos = mousePos - figCenter;
            
            rotX = relMousePos(1) / 200; % X-axis rotation
            rotY = relMousePos(2) / 200; % Y-axis rotation
            
            R_y = [cosd(rotX) 0 sind(rotX); 0 1 0; -sind(rotX) 0 cosd(rotX)];
            R_x = [1 0 0; 0 cosd(rotY) -sind(rotY); 0 sind(rotY) cosd(rotY)];
            
            
            newDirection = R_y * R_x * obj.currentCameraDirection';
            obj.currentCameraDirection = newDirection';
            
            targetPos = obj.currentCameraPosition + obj.currentCameraDirection;
            camtarget(obj.Axis, targetPos);
            camup(obj.Axis, -[0 1 0]);
        end



        function keypress(obj, ~, event)
            % Keyboard press callback
            stepSize = 10;
            fixedHeight = obj.currentCameraPosition(2);
            switch event.Key
                case 'w'
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * obj.currentCameraDirection;
                case 's'
                    obj.currentCameraPosition = obj.currentCameraPosition - stepSize * obj.currentCameraDirection;
                case 'a'
                    strafeDirection = cross(obj.currentCameraDirection, [0, 1, 0]);                      
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * strafeDirection;
                case 'd'
                    strafeDirection = cross([0, 1, 0], obj.currentCameraDirection);
                    obj.currentCameraPosition = obj.currentCameraPosition + stepSize * strafeDirection;
            end

            % Keep camera height constant
            obj.currentCameraPosition(2) = fixedHeight; 
            
            camup(obj.Axis, -[0 1 0]);
            campos(obj.Axis, obj.currentCameraPosition);
            camtarget(obj.Axis, obj.currentCameraPosition + obj.currentCameraDirection);
        end

        function mouseWheel(obj, ~,event)
            obj.Axis = gca;
            zoomFactor = 1.1;
            if event.VerticalScrollCount > 0
                % Herauszoomen
                camzoom(obj.Axis, 1/zoomFactor);
            elseif event.VerticalScrollCount < 0
                % Hineinzoomen
                camzoom(obj.Axis, zoomFactor);
            end
        end
    end
end

 