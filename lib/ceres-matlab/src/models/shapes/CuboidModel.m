classdef CuboidModel < ShapeModel
    % CuboidModel A class for generating a simple shape model based on a
    % cuboid
    properties
        dimensions
        
        vert1
        vert2
        vert3
    end
    
    methods
        function [self] = CuboidModel(varargin)
            % Parse the inputs:
            p = inputParser;
                defaultDimensions = [1;1;1];
                validDimensions = @(x) numel(x) == 3 && isnumeric(x);
                addParameter(p,'Dimensions',defaultDimensions,validDimensions);
            parse(p,varargin{:});
            
            % Extract the relevant information from the dimensions:
            x = p.Results.Dimensions(1)/2;
            y = p.Results.Dimensions(2)/2;
            z = p.Results.Dimensions(3)/2;
            
            % Define the simple cuboid geometry:
            geometry.faces = [1 3 2;
                              3 1 4;
                              4 7 3;
                              7 4 8;
                              8 4 5;
                              5 4 1;
                              5 1 2;
                              5 2 6;
                              6 2 3;
                              6 3 7;
                              5 6 7;
                              7 8 5];
            geometry.vertices = [-x -y -z;
                                  x -y -z;
                                  x  y -z;
                                 -x  y -z;
                                 -x -y  z;
                                  x -y  z;
                                  x  y  z;
                                 -x  y  z];
            
            % Inherit the ShapeModel super class:
            self@ShapeModel(geometry);
            
            % Store input dimensions as property:
            self.dimensions = p.Results.Dimensions;
            
            % Calcualte triangle structures for ray tracing:
            self.calculateVert123()
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
            self.bvh.aabb = [min(self.vertices), max(self.vertices)];
        end
        
        function [hit,intersections,normals] = rayTrace(self,ray)
            % The ray has been transformed into the a axis aligned body
            % frame of the cuboid, and so we can do a simple ray-box
            % intersection test:
            
            [intersections,~,~,~,xcoor] = TriangleRayIntersection(ray(1:3), ray(4:6), self.vert1, self.vert2, self.vert3);
            if any(intersections)
                hit = true;
                normals = self.face_normals(intersections,:)';
                intersections = xcoor(intersections,:)';
            else
                hit = false;
                normals = nan;
            end
        end
    end
end