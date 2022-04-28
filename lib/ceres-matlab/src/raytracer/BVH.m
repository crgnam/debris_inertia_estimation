classdef BVH < handle
    properties
        % Stored data:
        objects
        
        % Calculated acceleration structures:
        scene_aabb
        object_aabbs
    end
    
    methods
        function [self] = BVH(objects)
            % Initialize an empty set of object bounding boxes:
            object_aabbs = zeros(length(objects),6);
            
            % Get the bounding volumes for each object:
            for ii = 1:length(objects)
                objects{ii}.shape_model.buildBVH();
                object_aabbs(ii,:) = objects{ii}.shape_model.bvh.aabb;
            end
            
            % Obtain the overall scene axis aligned bounding box:
            self.scene_aabb = [min(object_aabbs(:,1:3)), max(object_aabbs(:,4:6))];
            self.object_aabbs = object_aabbs;
            self.objects = objects;
        end
    end
    
    methods (Access = public)
        function [] = draw(self)
            box = [self.scene_aabb(1), self.scene_aabb(4),...
                   self.scene_aabb(2), self.scene_aabb(5),...
                   self.scene_aabb(3), self.scene_aabb(6)];
            drawBox3d(box,'color','r'); hold on
            
            for ii = 1:size(self.object_aabbs,1)
                box = [self.object_aabbs(ii,1), self.object_aabbs(ii,4),...
                       self.object_aabbs(ii,2), self.object_aabbs(ii,5),...
                       self.object_aabbs(ii,3), self.object_aabbs(ii,6)];
                drawBox3d(box,'color','r')
            end
        end
        
        function [hit_flag,intersection,normal,hit_object] = rayCast(self, ray, any_hit)
            if nargin == 2
                any_hit = false;
            end
            
            % Initialize returns:
            hit_flag = false;
            intersection = nan(3,1);
            normal = nan(3,1);
            hit_object = [];
                
            % See the ray has intersected the scene:
            [hit_scene,~] = rayBoxIntersection(ray(1:3), ray(4:6), self.scene_aabb(1:3), self.scene_aabb(4:6));
            
            % If it has, see if the ray has intersected any of the objects:
            if hit_scene
                hits = nan(length(self.objects),8);
                ind = 1;
                for ii = 1:length(self.objects)
                    % Check if the ray intersects a given object:
                    [hit,intersections,normals] = self.objects{ii}.shape_model.rayTrace(ray);
                    
                    % If a hit was detected, store the intersection data:
                    if hit
                        hit_flag = true;
                        if any_hit
                            return
                        end
                        
                        % Store the values to be processed for closest hit:
                        try
                        num_intersections = size(intersections,2);
                        hit_insert = [true(num_intersections,1), ii*ones(num_intersections,1),...
                                      intersections', normals'];
                        hits(ind:ind+num_intersections-1,:) = hit_insert;
                        catch
                            disp('OH FUCK')
                        end
                        ind = ind+num_intersections+1;
                    end
                end
                hits(isnan(hits(:,1)),:) = [];
                
                % Determine the closest hit:
                if hit_flag
                    if size(hits,1) > 1
                        [~,dist] = normr(hits(:,3:5) - ray(1:3)');
                        closest = dist == min(dist);
                        hits = hits(closest,:);
                    end

                    hit_object = hits(2);
                    intersection = hits(3:5);
                    normal = hits(6:8);
                end
            end
        end
    end
end
