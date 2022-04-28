classdef Scene < handle
    % Scene A class for generating a scene of objects for simulation,
    % estimation, and rendering
    
    properties (SetAccess = private)
        camera
        sun
        objects
        
        % Calculated:
        bvh
    end
    
    methods 
        function [self] = Scene(camera,sun,objects)
            % Store all of the data into the scene:
            self.camera  = camera;
            self.sun     = sun;
            self.objects = objects;
        end
    end
    
    methods (Access = public)        
        function [image] = rayTrace(self,varargin)
            % Parse the input parameters:
            validScalar = @(x) numel(x) == 1 && isnumeric(x);
            validBounce = @(x) numel(x) == 1 && isnumeric(x) && (0<=x) && (x<=1);
            p = inputParser;
                addOptional(p,'NumberOfSamples',1,validScalar);
                addOptional(p,'NumberOfBounces',0,validBounce);
                addOptional(p,'NumberOfDiffuseBounceSamples',1,validScalar);
            parse(p,varargin{:});
            
            % TOOO: Can only support a single bounce iteration because its
            % hardcoded.  Need to make ray tracing recursive at some
            % point....
            
            % Generate a blank image:
            dims = [self.camera.camera_model.resolution(2), self.camera.camera_model.resolution(1)];
            image_r = zeros(dims(1),dims(2));
            image_g = zeros(dims(1),dims(2));
            image_b = zeros(dims(1),dims(2));
            
            % Generate camera rays:
            rays = self.camera.pixels_to_rays();
            sz = size(image_r);
            
            % Cast the rays through the BVH:
            parfor ii = 1:numel(image_r)
                [u,v] = ind2sub(sz,ii);
                for jj = 1:p.Results.NumberOfSamples
                    ray = self.camera.pixels_to_rays([v,u] + rand(1,2)-0.5);

                    % Determine the closest intersection:
                    [ray_hit,intersection,normal,object_id] = self.bvh.rayCast([self.camera.position; ray]);

                    % If a ray has hit, continue with shading computations:
                    if ray_hit                    
                        % Calculate the corresponding view and sun vectors:
                        light_ray = normc(self.sun.position - intersection');

                        % Check if the intersection point is in shadow:
                        bounce_point = intersection' + 1e-6*light_ray;
                        in_shadow = self.bvh.rayCast([bounce_point; light_ray],true);

                        if ~in_shadow
                            % Calculate the shading of the intersected point:
                            illum = self.objects{object_id}.material.shader([],[],normal,light_ray,1);
                            
                            % In addition, bounce the ray to additional
                            % objects for global illumination:
                            if p.Results.NumberOfBounces > 0
                                illum_diffuse = [0 0 0];
                                illum_specular = [0 0 0];
                                object_id_orig = object_id;
                                switch lower(self.objects{object_id}.material.type)
                                    case 'diffuse'
                                        for kk = 1:p.Results.NumberOfDiffuseBounceSamples
                                            % Calculate the bounced ray given the
                                            % material properties:
                                            bounced_ray = self.objects{object_id_orig}.material.bounceRay(bounce_point,ray,normal);

                                            % Ray trace the bounced ray in the scene:
                                            [ray_hit,intersection,normal,object_id] = self.bvh.rayCast(bounced_ray);
                                            
                                            % Calculate the illumination of
                                            % the secondary hit:
                                            if ray_hit
                                                % Calculate the corresponding view and sun vectors:
                                                light_ray = normc(self.sun.position - intersection');

                                                % Check if the intersection point is in shadow:
                                                bounce_point = intersection' + 1e-6*light_ray;
                                                in_shadow = self.bvh.rayCast([bounce_point; light_ray],true);
                                                
                                                if ~in_shadow
                                                    % Calculate the shading of the intersected point:
                                                    illum_diffuse = illum_diffuse + self.objects{object_id}.material.shader([],[],normal,light_ray,1);
                                                end
                                            end
                                        end
                                    case 'specular'
                                        % Calculate the bounced ray given the
                                        % material properties:
                                        bounced_ray = self.objects{object_id_orig}.material.bounceRay(bounce_point,ray,normal);

                                        % Ray trace the bounced ray in the scene:
                                        [ray_hit,intersection,normal,object_id] = self.bvh.rayCast(bounced_ray);

                                        % Calculate the illumination of
                                        % the secondary hit:
                                        if ray_hit
                                            % Calculate the corresponding view and sun vectors:
                                            light_ray = normc(self.sun.position - intersection');

                                            % Check if the intersection point is in shadow:
                                            bounce_point = intersection' + 1e-6*light_ray;
                                            in_shadow = self.bvh.rayCast([bounce_point; light_ray],true);

                                            if ~in_shadow
                                                % Calculate the shading of the intersected point:
                                                illum_specular = illum_specular + self.objects{object_id}.material.shader([],[],normal,light_ray,1);
                                            end
                                        end
                                    otherwise
                                        error('ONLY DIFFUSE MATERIALS ARE SUPPORTED AT THIS TIME')
                                end
                                
                                % Calculate overall illumination:
                                illum = illum + 0.5*illum_diffuse + 0.5*illum_specular;
                            end

                            % Insert illumination values into each image channel:
                            if jj == 1
                                image_r(ii) = illum(1);
                                image_g(ii) = illum(2);
                                image_b(ii) = illum(3);
                            else
                                image_r(ii) = mean([image_r(ii),illum(1)]);
                                image_g(ii) = mean([image_g(ii),illum(2)]);
                                image_b(ii) = mean([image_b(ii),illum(3)]);
                            end
                        end
                    end
                end
            end
            
            image = cat(3, image_r,image_g,image_b);
        end
        
        function [] = buildBVH(self)
            % Build an acceleration structure:
            self.bvh = BVH(self.objects);
        end
    end
    
    methods (Access = public)
        function [] = draw(self,varargin)
            p = inputParser;
                validScalar = @(x) isnumeric(x) && numel(x) == 1;
                addParameter(p,'CameraScale',1,validScalar);
                addParameter(p,'SunScale',1,validScalar);
            parse(p,varargin{:});
            
            % Draw the camera:
            self.camera.draw(p.Results.CameraScale,...
                             'FaceColor',[1,.65,0],...
                             'EdgeColor',[.5 .3 0],...
                             'FaceAlpha',.5);
                         
            % Draw the sun:
            self.sun.draw(p.Results.SunScale);
            light('Position',self.sun.position,'Style','infinite')
            
            % Draw each object in the scene:
            for ii = 1:length(self.objects)
                self.objects{ii}.draw();
            end
            
            view([0 30])
        end
        
        function [] = drawBVH(self,varargin)
            self.bvh.draw(varargin{:})
        end
    end
end