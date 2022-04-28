classdef KDTree < handle
    % KDTree A class meant for handling a KD-Tree for ray tracing
    % acceleration.  This is meant to accelerate the act of ray tracing a
    % single mesh geoemtry
    
    properties
        tree
        aabb
        max_depth
        max_triangles
        
        % Ray tracing data:
        potential_triangles
    end
    
    methods
        function [self] = KDTree(shape_model,varargin)
            % The number of leafs defines the number of subdivision
            p = inputParser;
            validShape = @(x) isa(x,'ShapeModel');
            defaultMaxTriangles = 10;
            addRequired(p,'shape_model',validShape);
            addParameter(p,'MaxTriangles',defaultMaxTriangles);
            parse(p,shape_model,varargin{:});
            self.max_triangles = p.Results.MaxTriangles;
            
            % Calculate the depth of the tree (number of divisions):
            num_triangles = size(shape_model.faces,1);
            self.max_depth = ceil(log2(num_triangles/self.max_triangles));
            
            % Format all data for fast lookup:
            tri_labels = 1:num_triangles;
            tri_centers = shape_model.face_centers;
            data = [tri_centers, tri_labels'];
            
            % Calculate the initial axis aligned bounding box:
            self.aabb = [min(shape_model.vertices), max(shape_model.vertices)];
            self.tree.aabb = self.aabb;
            self.tree.depth = 1;
            
            % Build the acceleration tree:
            self.makeTree(data);
        end
    end
    
    methods (Access = public)
        function [test_triangles] = rayCast(self,ray)
            % Initialize intersections:
            self.potential_triangles = [];
            
            % Traverse the KD-Tree testing each AABB against ray:
            self.rayAABBintersect(self.tree,ray);
            
            test_triangles = self.potential_triangles;
        end
    end
    
    methods (Access = public)
        function [] = drawAABBs(self,target_depth)
            if nargin == 1
                target_depth = self.max_depth;
            end
            if target_depth > self.max_depth
                error('Cannot draw depth higher than the max depth constructed')
            end
            
            % Draw the aabb:
            self.drawAABB(self.tree,target_depth)
        end
    end
    
    methods (Access = private)
        function [] = makeTree(self,data)
            % Initialize:
            L = self.tree.aabb(4:6) - self.tree.aabb(1:3);
            dim   = find(min(L) == L); % Initial dimension to split by
            
            % Initialize the recursion:
            self.tree = self.newBranches(self.tree,data,dim);
        end
        
        function [node] = newBranches(self,node,data,dim)
            % If we've reached the max depth, exit recursion:
            if node.depth == self.max_depth
                % Add the data to the leaves:
                node.triangles = data(:,4);
                return
            else
                % Continue cycle through the dimensions:
                if dim > 3
                    dim = 1;
                end
                
                % Split the data in the current dimension:
                midpoint = mean(data(:,dim));
                data_left = data(data(:,dim)<midpoint,:);
                data_right = data(data(:,dim)>=midpoint,:);
                
                
                % Calculate the new axis aligned bounding boxes:
                node.left.aabb = node.aabb;
                node.left.aabb(dim+3) = midpoint;
                node.left.depth = node.depth+1;
                
                node.right.aabb = node.aabb;
                node.right.aabb(dim) = midpoint;
                node.right.depth = node.depth+1;
                
                
                % Recursively calculate new branches:
                node.left  = self.newBranches(node.left,data_left,dim+1);
                node.right = self.newBranches(node.right,data_right,dim+1);
            end
        end
        
        function [] = drawAABB(self,node,target_depth)
            if node.depth == target_depth
                aabb = node.aabb;
                box = [aabb(1), aabb(4),...
                       aabb(2), aabb(5),...
                       aabb(3), aabb(6)];
                disp(length(node.triangles))
                drawBox3d(box,'color','r'); hold on
                grid on
                axis equal
                rotate3d on
            else
                self.drawAABB(node.left,target_depth)
                self.drawAABB(node.right,target_depth)
            end
        end
        
        function [] = rayAABBintersect(self,node,ray)
            % Test if ray intersects bounding boxes:
            if node.depth == self.max_depth
                % Store the potential triangles to test intersection with:
                self.potential_triangles = [self.potential_triangles;
                                            node.triangles];
            else
                [flag,~] = rayBoxIntersection(ray(1:3), ray(4:6), node.aabb(1:3), node.aabb(4:6));
                if flag
                    self.rayAABBintersect(node.left,ray)
                    self.rayAABBintersect(node.right,ray)
                else
                    return
                end
            end
        end
    end
end