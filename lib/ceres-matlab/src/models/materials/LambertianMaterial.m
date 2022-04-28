classdef LambertianMaterial < Material
    properties
        
    end
    
    methods
        function [self] = LambertianMaterial(varargin)
            self@Material(varargin{:});
            
            self.type = 'diffuse';
        end
    end
    
    methods (Access = public)
        function [bounced_ray] = bounceRay(~,intersection,~,normal)
            % Generate a random vector around the upper-half sphere:
            zed = [0;0;1];
            rand_angles = [(pi/2 - 0.3)*rand, 0, 2*pi*rand]; % Random angles between 0 and pi/2
            random_rotation = Attitude('EulerAngles','123',rand_angles);

            % Calculate the rotation to align the random vector with the given
            % normal:
            axis  = cross(zed,normal);
            angle = acos(dot(zed,normal));
            matrix_align = Attitude('AxisAngle',axis,angle);
            random_vector = matrix_align*random_rotation*zed;
            
            bounced_ray = [intersection; random_vector];
        end
        
        function [illum] = shader(self,tri,view_ray,normal,light_ray,intensity)
            illum = dot(light_ray,normal)*self.texture.getColorFromTriangle(tri)*intensity;
        end
    end
end