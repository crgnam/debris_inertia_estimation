function [X_hat, P, y_hat] = ukf(dynamics, measModel, X_hat, dt,...
                                 P, Q, R, meas_avail, meas,...
                                 alpha, beta, kappa, model_args)
    % Process the variable inputs:
    dynamics_args    = model_args{1};
    measurement_args = model_args{2};
    
    % Extract important values:
    n = length(meas);

    [SIGMAS,Wm,Wc,L] = u_sigmas(X_hat,P,alpha,beta,kappa);
    
    % Propagate estimate through dynamics:
    [X_hat, P, X_dev, SIGMAS2] = ut(dynamics, dt, SIGMAS, Wm, Wc, Q, L, dynamics_args{:});    
    
    % If measurement is available, perform kalman update:
    if any(meas_avail)
        % Calculate predicted measurement:
        [y_hat, Pyy, y_dev]  = ut(measModel, dt, SIGMAS, Wm, Wc, R, n, measurement_args{:});
        
        % Calculate cross-correlation covariance (3.266):
        Pxy = X_dev*diag(Wc)*y_dev';

        % Kalman Gain (3.251):
        K = Pxy*Pyy^-1;
        
        % State and Covariance Update (3.249):
        X_hat = X_hat + K*(meas - y_hat);
        P = P - K*Pxy';
    else
        y_hat = nan;
    end
    
    % Make sure covariance is positive semidefinite.
    P = posSemiDefCov(P);
end 