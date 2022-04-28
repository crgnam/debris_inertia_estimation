classdef Gravity < handle
    % GravityField An abstract class for all gravity field models
    
    properties
       mu
       inertial2self
       position
    end
    
    properties (Constant)
        G = 6.67430*10^-11; % Gravitational Constant
    end
    
    methods
        function [self] = Gravity(mu)
            self.mu = mu;
            self.inertial2self = eye(3);
            self.position = zeros(3,1);
        end
    end
    
    methods (Access = public)
        function [accel] = getAcceleration(self,r_inertial)
            % Convert point to gravity body frame:
            r_body = self.inertial2self*r_inertial + self.position;
            
            % A method for calculating the graviational acceleration
            accel = -self.mu*r_body/(norm(r_body)^3);
        end
        
        function [] = setPose(self,position,rotmat)
            self.inertial2self = rotmat;
            self.position = position;
        end
    end
    
    
    methods (Access = public)
        % These are methods for visualization:
        function [] = draw(self, num_lat_steps,num_long_steps,rho)
            % This method currently draws the gravity field by evaluating
            % the entire field over the entire latitude and longitude range
            % (taking a step defined as input) at a fixed distance.  
            %
            % TODO: Later versions will allow for generating more
            % traditional gravity anonaly data.
            
            % Generate all of the test points:
            longitude = linspace(-pi,pi,num_long_steps)';
            latitude = linspace(-pi/2,pi/2,num_lat_steps)';
            positions = zeros(length(longitude),length(latitude),3);
            for ii = 1:length(longitude)
                for jj = 1:length(latitude)
                    [x,y,z] = sph2cart(longitude(ii),latitude(jj),rho);
                    positions(ii,jj,:) = [x;y;z];
                end
            end
            [latitude,longitude] = meshgrid(latitude,longitude);
            
            % Evaluate the gravity field for all of the defined positions:
            accel = zeros(size(positions));
            if size(positions,3) == 3
                for ii = 1:size(positions,1)
                    for jj = 1:size(positions,2)
                        accel(ii,jj,:) = self.getAcceleration(squeeze(positions(ii,jj,:)));
                    end
                end
            end
            [~,accel_mag] = normw(accel);
            
            % Plot the gravity field:
            longitude = rad2deg(longitude);
            latitude  = rad2deg(latitude);
            surf(longitude,latitude,accel_mag,'EdgeColor','none'); axis equal
            c = colorbar;
            c.Label.String = 'Gravitational Acceleration (m/s^2)';
            view([0 90])
            xlabel('Longitude (deg)')
            ylabel('Latitude (deg)')
        end
    end
end