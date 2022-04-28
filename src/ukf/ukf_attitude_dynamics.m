function [X_next] = ukf_attitude_dynamics(dt,X, varargin)
    X_next = rk4(@rotational_dynamics_ukf,dt,X,varargin{:});
end