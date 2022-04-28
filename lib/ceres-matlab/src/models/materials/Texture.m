classdef Texture < handle
    % Texture A class for dealing with texturing
    properties
        texture_data (:,3) double % Color for each triangle in associated mesh object
        
        per_tri
    end
    
    methods
        function [self] = Texture(texture_data)
            % The supplied texture data can either be:
            %   - 1x3 color data (it will then be assumed all triangles of
            %     the mesh are triangle in nature)
            %   - Nx3 color data (where N is the number of faces for the
            %     corresponding object this texture applies to.
            
            % Verify it is of the correct type:
            if ~all((0 <= texture_data) & (texture_data <= 1))
                error('ALL TEXTURE DATA MUST BE A VALID RGB TRIPLET BETWEEN 0 AND 1')
            end
            self.texture_data = texture_data;
            
            % Exclude unimplemented features:
            if size(self.texture_data,1) > 1
                self.per_tri = true;
                error('PER TRIANGLE TEXTURING IS NOT YET IMPLEMENTED')
            else
                self.per_tri = false;
            end
        end
    end
    
    methods (Access = public)
        function [color] = getColorFromTriangle(self,tri)
            if self.per_tri
                color = self.texture_data(tri,:);
            else
                color = self.texture_data;
            end
        end
    end
    
end