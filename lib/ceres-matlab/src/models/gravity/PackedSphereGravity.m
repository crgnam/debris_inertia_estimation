classdef PackedSphereGravity < Gravity
    % FiniteSphereGravity A class for modeling the gravity field of a
    % finite collection of spheres
    
    properties
        spheres
        masses
    end
    
    methods
        function [self] = PackedSphereGravity(spheres,masses)
            if numel(masses) == 1
                masses = masses/spheres.num_spheres;
                masses = masses*ones(spheres.num_spheres,1);
            end
            
            % Inherit from the GravityField super class:
            mu = Gravity.G*sum(masses);
            self@Gravity(mu);
            
            self.spheres = spheres;
            self.masses  = masses;
        end
    end
    
    methods (Access = public)
        function [accel] = getAcceleration(self,r_inertial)
            % Convert point to gravity body frame:
            r_body = self.inertial2self*r_inertial + self.position;
            
            % Calculate relative position to all test masses:
            r_rel = self.spheres.origins - r_body';
            m = self.masses;
            [r_rel_u, r_rel_mag] = normr(r_rel);

            % Acceleration due to gravity:
            accel = self.inertial2self'*self.G*(sum(m.*r_rel_u./(r_rel_mag.^2),1))';
        end
    end
end