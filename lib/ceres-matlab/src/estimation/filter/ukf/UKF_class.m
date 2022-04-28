classdef UKF_class < handle
    %@code{true}
    properties (Access = public)
        % Estimator:
        x_hat % Estimate
        P % Estimate Covariance Matrix
        Q % Process Noise Covariance Matrix
        R % Measurement Noise Covariance Matrix

        measurement % The actual measurement
        predicted_measurement % The filter's predicted measurement
        measAvails
        
        % Models:
        dynamics_model
        measurement_model
        model_args        
        
        % Tuning parameters:
        alpha
        beta
        kappa
        
        % Logs:
        x_hat_log
        P_log
        sig3_log
        measurement_log
        predicted_log
        measAvail_log
    end
    
    %% Constructor
    methods
        function [self] = UKF_class(x_hat,P,Q,R,alpha,beta,kappa,tspan,...
                                    dynamics_model,dynamics_args,...
                                    measurement_model,measurement_args)
            % Format appropriately:
            if isrow(x_hat)
                x_hat = x_hat';
            end
            
            % Check the inputs for inconsistencies:
            assert(all(size(P)==size(Q)), 'P and Q must be the same size')
            assert(size(x_hat,1)==size(P,1), 'P must have the same number of rows as x_hat')
            assert(isa(dynamics_model,'function_handle'), 'dynamics_model must be a function_handle')
            assert(isa(measurement_model,'function_handle'), 'measurement_model must be a function_handle')
            
            % Store values:
            self.x_hat = x_hat;
            self.P = P;
            self.Q = Q;
            self.R = R;
            self.dynamics_model = dynamics_model;
            self.measurement_model = measurement_model;
            self.model_args  = {dynamics_args, measurement_args};
            self.alpha = alpha;
            self.beta  = beta;
            self.kappa = kappa;
            
            % Preallocate Logs:
            L = length(tspan);
            self.x_hat_log       = zeros(size(self.x_hat,1),L);
%             self.P_log           = zeros(size(self.P,1),size(self.P,2),L);
            self.sig3_log        = zeros(size(self.x_hat,1),L);
            self.measurement_log = nan(size(self.R,1),L);
            self.predicted_log   = nan(size(self.R,1),L);
            self.measAvail_log   = false(size(self.R,1),L);
            
            % Initial log values:
            self.x_hat_log(:,1) = self.x_hat;
            self.P_log(:,:,1)   = self.P;
            self.sig3_log(:,1)  = 3*sqrt(diag(self.P));
        end
    end
    
    %% Public Methods:
    methods (Access = public)
        % Run the unscented kalman filter to obtain an new estimate:
        function [] = estimate(self, dt, measurement, measAvails)
            [x_hat2,P2,y_hat] = ukf(self.dynamics_model, self.measurement_model,...
                                    self.x_hat, dt,...
                                    self.P, self.Q, self.R, measAvails, measurement,...
                                    self.alpha, self.beta, self.kappa, self.model_args);
            self.x_hat = x_hat2;
            self.P = P2;
            self.measurement = measurement;
            self.predicted_measurement = y_hat;
            self.measAvails = measAvails;
        end
        
        % Update the process noise matrix:
        function [] = updateQ(self,Q_new)
            self.Q = Q_new;
        end
        
        % Update the model arguments:
        function [] = update_args(self,dynamics_args,measurement_args)
            self.model_args = {dynamics_args, measurement_args};
        end
        
        % Log data for a given timestep:
        function [] = log(self,ii)
            self.x_hat_log(:,ii) = self.x_hat;
            self.P_log(:,:,ii)   = self.P;
            self.sig3_log(:,ii)  = 3*sqrt(diag(self.P));
            self.measurement_log(self.measAvails,ii) = self.measurement;
            self.predicted_log(self.measAvails,ii)   = self.predicted_measurement;
            self.measAvail_log(:,ii)   = self.measAvails;
        end
    end
end