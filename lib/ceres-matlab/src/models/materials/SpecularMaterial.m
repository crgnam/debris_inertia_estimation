classdef SpecularMaterial < Material
    properties
        
    end
    
    methods
        function [self] = SpecularMaterial(varargin)
            self@Material(varargin{:});
            
            self.type = 'specular';
        end
    end
    
    methods (Access = public)
        function [bounced_ray] = bounceRay(~,intersection,ray,normal)
            % Generate a reflected vector:
            reflected_ray = ray - 2*dot(ray,normal')*normal';
            bounced_ray = [intersection; reflected_ray];
        end
        
        function [illum] = shader(self,tri,view_ray,normal,light_ray,intensity)
            illum = dot(light_ray,normal)*self.texture.getColorFromTriangle(tri)*intensity;
        end
    end
end