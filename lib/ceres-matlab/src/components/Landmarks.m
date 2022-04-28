classdef Landmarks < handle
    properties
        position
        inertial2self
        
        positions_body
        normals_body
        P
        sig3
        
        positions
        normals
        
        iter_count
        missed
        num_lmks
        
        max_view_angle
        visible
        
        min_iter_count
        max_missed_images
         
        
        labels
        
        img
        kps
        desc
        
        detected %(1xN) boolean
        measurement %(2xN) pixel coordinates
        
        % Visualization
        vis
    end
    
    methods
        function [self] = Landmarks(max_view_angle, max_missed_images, min_iter_count)
            self.max_view_angle = max_view_angle;
            self.max_missed_images = max_missed_images;
            self.min_iter_count = min_iter_count;
            self.num_lmks = 0;
            
            % Initialize a pose:
            self.setPose(zeros(3,1), eye(3));
            
            % Initialize empty struct for visualization handles:
            self.vis = [];
        end
        
        function [] = setPose(self,position,inertial2self)
            self.inertial2self = inertial2self;
            self.position = position;
            
            % Rotate:
            if ~isempty(self.positions_body)
                self.positions = inertial2self'*self.positions_body + position;
                self.normals = inertial2self'*self.normals_body + position;
            end
        end
        
        function [] = addNew(self,new_positions,new_normals,new_P,img,kps,desc)
            % Update the new landmarks:
            self.img  = img;
            num_new_lmks = size(new_positions,2);
            if self.num_lmks == 0
                self.positions_body = new_positions;
                self.normals_body = new_normals;
                self.kps  = kps;
                self.desc = desc;
                self.missed = zeros(1,size(kps,2));
                self.iter_count = zeros(1,size(kps,2));
                if length(size(new_P)) == 2
                    self.P = repmat(new_P,1,1,num_new_lmks);
                    self.sig3 = 3*repmat(sqrt(diag(new_P)),1,num_new_lmks);
                    
                elseif length(size(new_P)) == 3
                    self.P = new_P;
                    self.sig3 = zeros(3,num_new_lmks);
                    for ii = 1:num_new_lmks
                        self.sig3(:,ii) = 3*sqrt(diag(new_P(:,:,ii)));
                    end
                else
                    error('Invalid value for uncertainties was provided')
                end
            else
                self.positions_body = [self.positions_body, new_positions];
                self.normals_body = [self.normals_body, new_normals];
                self.kps  = [self.kps, kps];
                self.desc = [self.desc, desc];
                self.missed = [self.missed, zeros(1,size(kps,2))];
                self.iter_count = [self.iter_count,...
                                   zeros(1,size(kps,2))];
                if all(size(new_P) == [3,3])
                    self.P = cat(3,self.P,repmat(new_P,1,1,num_new_lmks));
                    self.sig3 = [self.sig3, 3*repmat(sqrt(diag(new_P)),1,num_new_lmks)];
                    
                elseif all(size(new_P) == [3,3,num_new_lmks])
                    self.P = cat(3,self.P,new_P);
                    sig3_insert = zeros(3,num_new_lmks);
                    for ii = 1:num_new_lmks
                        sig3_insert(:,ii) = 3*sqrt(diag(new_P(:,:,ii)));
                    end
                    self.sig3 = [self.sig3, sig3_insert];
                else
                    error('Invalid value for uncertainties was provided')
                end
            end
            
            self.num_lmks = size(self.positions_body,2);
            
            % Set initial values:
            self.detected = [self.detected, true(1,num_new_lmks)];
            
            % Set the pose:
            self.setPose(self.position, self.inertial2self);
        end
        
        function [] = removeOld(self)
            % If its supposed to be visible
            if self.num_lmks > 0
                self.missed = self.missed + self.visible & ~self.detected;
                self.iter_count = self.iter_count + 1;
                remove_inds = [];
                
                % Find landmarks that have been missed too much:
                if any(self.missed >= self.max_missed_images)
                    remove_inds = find(self.missed >= self.max_missed_images);
                end
                
                % Look for features that became invisible after a single
                % iteration:
                if any(self.iter_count <= self.min_iter_count & ~self.visible)
                    remove_inds2 = find(self.iter_count >= 1 & ~self.visible);
                    remove_inds = union(remove_inds, remove_inds2);
                end
                
                % Remove the features:
                if ~isempty(remove_inds)
                    self.P(:,:,remove_inds) = [];
                    self.sig3(:,remove_inds) = [];
                    self.positions(:,remove_inds) = [];
                    self.normals(:,remove_inds) = [];
                    self.positions_body(:,remove_inds) = [];
                    self.normals_body(:,remove_inds) = [];
                    self.kps(:,remove_inds) = [];
                    self.desc(:,remove_inds) = [];
                    self.detected(:,remove_inds) = [];
                    self.visible(:,remove_inds) = [];
                    self.missed(:,remove_inds) = [];
                    self.iter_count(:,remove_inds) = [];
                    disp(['Removed ', num2str(numel(remove_inds)), ' points'])
                end
            end
        end
        
        function [] = determineVisible(self,sun_vector,camera)            
            % Detect points that are pointed towards the camera:
            if ~isempty(self.positions)
                normals_camera = camera.inertial2self*self.normals;
                in_view = normals_camera(3,:)>0;

                % Detect points which meet with viewing angle requirement:
                rays   = normc(self.positions - camera.position);
                angled = acos(sum(rays.*-self.normals,1)) < self.max_view_angle;

                % Detect points that are illuminated:
                if ~isempty(sun_vector)
                    dir_sgn = sum(sun_vector.*self.normals,1);
                    illuminated = dir_sgn>0;
                else
                    illuminated = true(size(angled));
                end

                % Determine which landmarks are in the camera field of view:
                [~,in_fov] = camera.points_to_pixels(self.positions);

                % Select only points that are in FOV, illuminated, and visible:
                self.visible = in_view & angled & illuminated & in_fov';
            else
                self.visible = [];
            end
        end            
    end
    
    %% Public Visualization Methods:
    methods (Access = public)
        function [] = reset(self)
            self.vis = [];
        end
        
        function [] = drawMap(self,scale,marker_size,varargin)
            % Draw the new plot:
            [~,c] = normc(self.sig3);
            
            % Convert to lat lon coordinates:
            [lat,lon,~] = cart2sph(self.positions_body(1,:),...
                                   self.positions_body(2,:),...
                                   self.positions_body(3,:));
            lat = scale*(rad2deg(lat)+180);
            lon = scale*(rad2deg(lon)+90);
            % Draw the map:
            if isempty(self.vis)
                self.vis = scatter(lat,lon,...
                                   marker_size,c,varargin{:}); hold on
                cMap = [linspace(0,1,128)', ones(128,1), zeros(128,1);
                        ones(128,1), linspace(1,0,128)', zeros(128,1)];
                colormap(cMap);
                colorbar;
                caxis([0, 5]);
            else
                if numel(self.vis.CData) == 3
                    c = self.vis.CData;
                end
                set(self.vis,'XData',lat,...
                             'YData',lon,...
                             'CData',c);
            end
        end
        
        function [] = drawBest(self,marker_size,limit,varargin)
            % Draw the new plot:
            [~,c] = normc(self.sig3);
            best_inds = find(c < limit);
            if isempty(self.vis)
                self.vis = scatter3(self.positions(1,best_inds),...
                                    self.positions(2,best_inds),...
                                    self.positions(3,best_inds),...
                                    marker_size,c(best_inds),varargin{:}); hold on
                cMap = [linspace(0,1,128)', ones(128,1), zeros(128,1);
                        ones(128,1), linspace(1,0,128)', zeros(128,1)];
                colormap(cMap);
                colorbar;
                caxis([0, 30]);
                axis equal
            else
                try
                    if numel(self.vis.CData) == 3
                        c = self.vis.CData;
                    end
                    set(self.vis,'XData',self.positions(1,best_inds),...
                                 'YData',self.positions(2,best_inds),...
                                 'ZData',self.positions(3,best_inds),...
                                 'CData',c);
                catch
                    self.vis = [];
                end
            end
        end
        
        function [] = draw(self,marker_size,varargin)
            % Draw the new plot:
            [~,c] = normc(self.sig3);
            if isempty(self.vis)
                self.vis = scatter3(self.positions(1,:),...
                                    self.positions(2,:),...
                                    self.positions(3,:),...
                                    marker_size,c,varargin{:}); hold on
                cMap = [linspace(0,1,128)', ones(128,1), zeros(128,1);
                        ones(128,1), linspace(1,0,128)', zeros(128,1)];
                colormap(cMap);
                colorbar;
                caxis([0, 30]);
            else
                if numel(self.vis.CData) == 3
                    c = self.vis.CData;
                end
                set(self.vis,'XData',self.positions(1,:),...
                             'YData',self.positions(2,:),...
                             'ZData',self.positions(3,:),...
                             'CData',c);
            end
        end
        
        function [] = drawVisible(self,marker_size,varargin)
            % Draw the new plot:
            [~,c] = normc(self.sig3(:,self.visible));
            if isempty(self.vis)
                self.vis = scatter3(self.positions(1,self.visible),...
                                    self.positions(2,self.visible),...
                                    self.positions(3,self.visible),...
                                    marker_size,c,varargin{:}); hold on

            else
                if numel(self.vis.CData) == 3
                    c = self.vis.CData;
                end
                set(self.vis,'XData',self.positions(1,self.visible),...
                             'YData',self.positions(2,self.visible),...
                             'ZData',self.positions(3,self.visible),...
                             'CData',c);
            end
        end
    end
end