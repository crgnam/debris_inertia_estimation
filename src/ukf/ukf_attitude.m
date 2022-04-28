function [X_hat, P, y_hat, q_hat] = ukf_attitude(dynamics, measModel, X_hat, dt,...
                                          P, Q, R, meas_avail, meas,...
                                          alpha, beta, kappa, model_args,...
                                          q_hat_m)
    % Process the variable inputs:
    dynamics_args    = model_args{1};
    measurement_args = model_args{2};
    
    % Extract important values:
    n = length(meas);

    % Generate sigma points:
    [SIGMAS,Wm,Wc] = u_sigmas(X_hat,P,alpha,beta,kappa);
    
    % Convert the attitude error to a quaternion:
    SIGMAS_q = dq2q(SIGMAS(1:3,:),q_hat_m);
    SIGMAS = [SIGMAS_q; SIGMAS(4:end,:)];
    
    % Propagate estimate through dynamics:
    [X_hat,P,X_dev,~,q_hat_p] = ut2(dynamics, dt, SIGMAS, Wm, Wc, Q, dynamics_args{:});
    
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
    
    % Form the output attitude:
    q_hat = dq2q(X_hat(1:3),q_hat_p);
    q_hat = q_hat/norm(q_hat);
end 