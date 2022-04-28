classdef SphericalHarmonicGravity < Gravity
    % SphericalHarmonicGravity A class for modeling the gravity field
    % described by spherical harmonics
    
    properties
        Cnm
        Snm
        reference_radius
    end
    
    methods
        function [self] = SphericalHarmonicGravity(mu,varargin)
            % Parse the inputs:
            validScalar = @(x) isnumeric(x) && numel(x) == 1;
            p = inputParser;
            p.KeepUnmatched = true;
                addParameter(p,'Cnm',1,@isnumeric)
                addParameter(p,'Snm',0,@isnumeric)
                addParameter(p,'ReferenceRadius',1,validScalar)
            parse(p,varargin{:});
            
            % Inherit from the GravityField super class:
            self@Gravity(mu);
            
            % Store the values:
            self.Cnm = p.Results.Cnm;
            self.Snm = p.Results.Snm;
            self.reference_radius = p.Results.ReferenceRadius;
        end
    end
    
    methods (Access = public)
        function [accel] = getAcceleration(self,state)
            r_inertial = state(1:3);
            
            % Calculate nmax values:
            n_max = size(self.Cnm,1)-1;
            m_max = n_max-1;

            % Convert point to gravity body frame:
            r_body = self.inertial2self*r_inertial + self.position;
            
            % Auxiliary quantities
            d = norm(r_body);
            latgc = asin(r_body(3)/d);
            lon = atan2(r_body(2),r_body(1));

            [pnm, dpnm] = self.Legendre(n_max, m_max, latgc);

            dUdr = 0;
            dUdlatgc = 0;
            dUdlon = 0;
            q3 = 0; q2 = q3; q1 = q2;
            for n = 0:n_max
                b1 = (-self.mu/d^2)*(self.reference_radius/d)^n*(n+1);
                b2 =  (self.mu/d)*(self.reference_radius/d)^n;
                b3 =  (self.mu/d)*(self.reference_radius/d)^n;
                for m = 0:n
                    q1 = q1 + pnm(n+1,m+1)*(self.Cnm(n+1,m+1)*cos(m*lon)+self.Snm(n+1,m+1)*sin(m*lon));
                    q2 = q2 + dpnm(n+1,m+1)*(self.Cnm(n+1,m+1)*cos(m*lon)+self.Snm(n+1,m+1)*sin(m*lon));
                    q3 = q3 + m*pnm(n+1,m+1)*(self.Snm(n+1,m+1)*cos(m*lon)-self.Cnm(n+1,m+1)*sin(m*lon));
                end
                dUdr     = dUdr     + q1*b1;
                dUdlatgc = dUdlatgc + q2*b2;
                dUdlon   = dUdlon   + q3*b3;
                q3 = 0; q2 = q3; q1 = q2;
            end

            % Body-fixed acceleration
            r2xy = r_body(1)^2+r_body(2)^2;

            ax = (1/d*dUdr-r_body(3)/(d^2*sqrt(r2xy))*dUdlatgc)*r_body(1)-(1/r2xy*dUdlon)*r_body(2);
            ay = (1/d*dUdr-r_body(3)/(d^2*sqrt(r2xy))*dUdlatgc)*r_body(2)+(1/r2xy*dUdlon)*r_body(1);
            az =  1/d*dUdr*r_body(3)+sqrt(r2xy)/d^2*dUdlatgc;

            accel = self.inertial2self'*[ax ay az]';
        end
    end
    
    methods (Access = public)
        % These are methods used in the estimation process:
        function [] = setCnm(self,Cnm)
            self.Cnm = Cnm;
        end
        
        function [] = setSnm(self,Snm)
            self.Snm = Snm;
        end
        
        function [] = setReferenceRadius(self,reference_radius)
            self.reference_radius = reference_radius;
        end
    end
    
    methods (Access = private)
        % Back-end computational functions:
        function [pnm, dpnm] = Legendre(~,n,m,fi)
            pnm = zeros(n+1,m+1);
            dpnm = zeros(n+1,m+1);

            pnm(1,1)=1;
            dpnm(1,1)=0;
            pnm(2,2)=sqrt(3)*cos(fi);
            dpnm(2,2)=-sqrt(3)*sin(fi);
            % diagonal coefficients
            for i=2:n    
                pnm(i+1,i+1)= sqrt((2*i+1)/(2*i))*cos(fi)*pnm(i,i);
            end
            for i=2:n
                dpnm(i+1,i+1)= sqrt((2*i+1)/(2*i))*((cos(fi)*dpnm(i,i))- ...
                              (sin(fi)*pnm(i,i)));
            end
            % horizontal first step coefficients
            for i=1:n
                pnm(i+1,i)= sqrt(2*i+1)*sin(fi)*pnm(i,i);
            end
            for i=1:n
                dpnm(i+1,i)= sqrt(2*i+1)*((cos(fi)*pnm(i,i))+(sin(fi)*dpnm(i,i)));
            end
            % horizontal second step coefficients
            j=0;
            k=2;
            while(1)
                for i=k:n        
                    pnm(i+1,j+1)=sqrt((2*i+1)/((i-j)*(i+j)))*((sqrt(2*i-1)*sin(fi)*pnm(i,j+1))...
                        -(sqrt(((i+j-1)*(i-j-1))/(2*i-3))*pnm(i-1,j+1)));
                end
                j = j+1;
                k = k+1;
                if (j>m)
                    break
                end
            end
            j = 0;
            k = 2;
            while(1)
                for i=k:n        
                    dpnm(i+1,j+1)=sqrt((2*i+1)/((i-j)*(i+j)))*((sqrt(2*i-1)*sin(fi)*dpnm(i,j+1))...
                         +(sqrt(2*i-1)*cos(fi)*pnm(i,j+1))-(sqrt(((i+j-1)*(i-j-1))/(2*i-3))*dpnm(i-1,j+1)));
                end
                j = j+1;
                k = k+1;
                if (j>m)
                    break
                end
            end
        end
    end
    
    % Methods for fitting a spherical harmonic model to a reference field:
    methods (Static)
        function [Cnm_vec, Snm_vec] = coeffs2vec(Cnm,Snm)
            % Ignore first two rows of Cnm, and Snm.  Also, ignore first column of
            % Snm.  Finally, only consider lower triangular form of both (with
            % above restrictions)
            N = size(Cnm,1);
            Cnm_vec = zeros((1+N)*N/2 - 3,1);
            Snm_vec = zeros((1+N)*N/2 - N -1,1);
            kk = 1;
            for ii = 3:N
               for jj = 1:ii
                  Cnm_vec(kk) = Cnm(ii,jj); 
                  kk = kk+1;
               end
            end

            kk = 1;
            for ii = 3:N
                for jj = 2:ii
                    Snm_vec(kk) = Snm(ii,jj);
                    kk = kk+1;
                end
            end
        end
        
        function [Cnm,Snm] = vec2coeffs(Cnm_Snm_vec)
            % Calculate size of the Cnm coefficient matrix:
            L = size(Cnm_Snm_vec,1);
            for ii = 1:2000
                if L == SphericalHarmonicGravity.eval(ii)
                    N = ii+1;
                    break
                end
            end
            Cnm = zeros(N);
            Snm = zeros(N);

            % Split appropriately:
            num_Snm = (L-N)/2 + 1;
            num_Cnm = L - num_Snm;
            Cnm_vec = Cnm_Snm_vec(1:num_Cnm);
            Snm_vec = Cnm_Snm_vec(num_Cnm+1:end);

            % Scale factor to try to maintain numerical stability:   
            kk = 1;
            for ii = 3:N
               for jj = 1:ii
                  Cnm(ii,jj) = Cnm_vec(kk);
                  kk = kk+1;
               end
            end
            Cnm(1) = 1;

            kk = 1;
            for ii = 3:N
                for jj = 2:ii
                    Snm(ii,jj) = Snm_vec(kk);
                    kk = kk+1;
                end
            end
        end

        function [val] = eval(n)
            % Function to get the appropriate size:
            step = 5;
            val = 0;
            for ii = 1:n-1
                val = val+step;
                step = step+2;
            end
        end
        
        function [sphharm_field] = fitField(N,M,reference_radius,reference_field,options)
            % Initialize Coefficients based on defined input dimensions:
            [Cnm_vec, Snm_vec] = SphericalHarmonicGravity.coeffs2vec(zeros(N),zeros(M));
            num_coeffs = length(Cnm_vec)+length(Snm_vec);
            x0 = zeros(num_coeffs, 1);
            
            % Generate a set of test points:
            v = icosphere(3); % Icosphere used as it is unbiased
            scale = 2*reference_radius;
            test_points = scale*v.Vertices';

            % Evaluate the reference field:
            accel = zeros(size(test_points));
            for ii = 1:size(test_points,2)
                accel(:,ii) = reference_field.getAcceleration(test_points(:,ii));
            end
            
            % Create the field:
            mu  = reference_field.mu;
            [Cnm, Snm] = SphericalHarmonicGravity.vec2coeffs([Cnm_vec;Snm_vec]);
            sphharm_field = SphericalHarmonicGravity(mu,'Cnm',Cnm,'Snm',Snm,'ReferenceRadius',reference_radius);
            
            % Run optimization for whichever model was provided:
            if nargin == 4
                x_out = fmincon(@(x) sphharm_field.cost(x,accel,test_points), x0,...
                                [],[],[],[],[],[],[]);
            elseif nargin == 5
                x_out = fmincon(@(x) sphharm_field.cost(x,accel,test_points), x0,...
                                [],[],[],[],[],[],[],options);
            end
            [Cnm, Snm] = SphericalHarmonicGravity.vec2coeffs(x_out);
            
            sphharm_field.Cnm = Cnm;
            sphharm_field.Snm = Snm;
        end
    end
    
    methods (Access = private)
        function [eval] = cost(self,x,accel_ref,test_points)
            % Cost function for fitting field
            
            % Unpack spherical harmonic components and store:
            [self.Cnm, self.Snm] = self.vec2coeffs(x);

            % Evaluate the current field:
            accel = zeros(size(test_points));
            for ii = 1:size(test_points,2)
                accel(:,ii) = self.getAcceleration(test_points(:,ii));
            end
            
            % Remove nans (numerical issues) TODO: Fix whatever is causing
            % them
            remove = sum(isnan(accel),1) > 0;
            accel_ref(:,remove) = [];
            accel(:,remove) = [];

            % Calculate cost:
            max_accel = max(max(accel));
            max_accel_ref = max(max(accel_ref));
            [~,n] = normc(accel/max_accel - accel_ref/max_accel_ref);
            eval = norm(n(:));
        end 
    end
end