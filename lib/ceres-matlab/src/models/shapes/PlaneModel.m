classdef PlaneModel < ShapeModel
    % CuboidModel A class for generating a simple shape model based on a
    % cuboid
    properties
        dimensions
        
        vert1
        vert2
        vert3
    end
    
    methods
        function [self] = PlaneModel(varargin)
            % Parse the inputs:
            p = inputParser;
                defaultRadius = 1;
                validDimensions = @(x) numel(x) == 2 && isnumeric(x);
                addParameter(p,'Dimensions',defaultRadius,validDimensions);
            parse(p,varargin{:});
            
            % Extract the relevant information from the dimensions:
            x = p.Results.Dimensions(1)/2;
            y = p.Results.Dimensions(2)/2;
            
            % Create a placeholder spherical geometry:
            geometry.faces    = [1 2 3;
                                 3 4 1];
            geometry.vertices = [-x -y 0;
                                  x -y 0;
                                  x  y 0;
                                 -x  y 0];
            
            % Inherit the ShapeModel super class:
            self@ShapeModel(geometry);
            
            % Store input dimensions as property:
            self.dimensions = p.Results.Dimensions;
            
            % Calculate triangle structures for ray tracing:
            self.calculateVert123();
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
            
            self.calculateVert123()
        end
        
        function [] = calculateVert123(self)
            self.vert1 = self.vertices(self.faces(:,1),:);
            self.vert2 = self.vertices(self.faces(:,2),:);
            self.vert3 = self.vertices(self.faces(:,3),:);
        end
        
        function [] = buildBVH(self)
            self.bvh.aabb = [min(self.vertices(:,1:2)) -1 max(self.vertices(:,1:2)) 1];
        end
        
        function [hit,intersection,normal] = rayTrace(self,ray)
            % Treat plane as a set of two triangles and perform ray tracing
            % that way:
            [intersection,~,~,~,xcoor] = TriangleRayIntersection(ray(1:3), ray(4:6), self.vert1, self.vert2, self.vert3);
            if any(intersection)
                hit = true;
                intersection = xcoor(intersection,:)';
                normal = repmat(self.face_normals(1,:)',1,size(intersection,2));
            else
                hit = false;
                normal = nan;
            end
        end
    end
end