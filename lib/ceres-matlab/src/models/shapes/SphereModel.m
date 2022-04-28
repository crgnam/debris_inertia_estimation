classdef SphereModel < ShapeModel
    % CuboidModel A class for generating a simple shape model based on a
    % cuboid
    properties
        radius
        origin
    end
    
    methods
        function [self] = SphereModel(varargin)
            % Parse the inputs:
            p = inputParser;
                defaultRadius = 1;
                validScalar = @(x) numel(x) == 1 && isnumeric(x);
                addParameter(p,'Radius',defaultRadius,validScalar);
            parse(p,varargin{:});
            
            % Extract the relevant information from the dimensions:
            R = p.Results.Radius(1);
            
            % Create a placeholder spherical geometry:
            [X,Y,Z] = sphere(10);
            geometry = surf2patch(R*X,R*Y,R*Z);
            
            % Inherit the ShapeModel super class:
            self@ShapeModel(geometry);
            
            % Store input dimensions as property:
            self.radius = R;
        end
    end
    
    methods (Access = public)
        function [] = applyPose(self,position,attitude)
            % Adjust positions:
            self.face_centers = (attitude*self.face_centers_init')' + position';
            self.vertices = (attitude*self.vertices_init')' + position';
            
            % Adjust normals:
            self.vertex_normals = (attitude*self.vertex_normals_init')';
            self.face_normals = (attitude*self.face_normals_init')';
            
            % Store the origin:
            self.origin = position;
        end
        
        function [] = buildBVH(self)
            self.bvh.aabb = self.radius*[-1 -1 -1 1 1 1] + [self.origin' self.origin'];
        end
        
        function [hit,intersections,normals] = rayTrace(self,ray)
            % Initialize returns:
            hit = false;
            normals = nan(3,2);
                    
            % Perform ray-sphere intersection test:
            intersections = intersectLineSphere(ray', [self.origin', self.radius]);
            
            if all(~isnan(intersections))
                % Check for intersections behind the ray origin:
                dirs_to_intersect = normr(intersections - ray(1:3)');
                cos_ang = sum(dirs_to_intersect.*repmat(ray(4:6)',2,1),2);
                infront = cos_ang > 0;
                intersections(~infront,:) = [];
                if any(infront)
                    hit = true;
                    intersections = intersections';
                    normals = normc(intersections - self.origin);
                end
            end
        end
    end
end