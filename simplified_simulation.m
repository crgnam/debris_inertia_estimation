matlabrc; clc; close all; rng(1);
addpath(genpath('src'))
addpath(genpath('lib'))

% Flag for if you should show the animation:
animate = true;

% Simulation timespan:
dt = 1;
duration = 5*100;
tspan = dt:dt:duration;

% Generate the truth points:
pts = icosphere(2);
landmarks = pts.Vertices';
landmarks = randn(3,10);

% Create the camera model:
focal_length = 3.6/1000;
sensor_size = 3.76/1000;
cam_model = PinholeModel('FocalLength',focal_length,'SensorSize',sensor_size);
camera = Camera('CameraModel',cam_model);
camera.SetPose([0;0;5],eye(3));

% Create the UKF camera model:
camera_ukf = Camera('CameraModel',cam_model);
camera_ukf.SetPose([0;0;5],eye(3));

% Setup the dynamics:
q0 = [0; 0; 0; 1];
w0 = [0.05; 0.05; 0.05];
J = [1  0  0;
     0  1  0;
     0  0  3];

% Preallocate memory:
L = length(tspan);
X = zeros(4+3,L);
X(:,1) = [q0; w0];

num_states = 3+3+3;
X_hat = zeros(num_states,L);
q_hat = zeros(4,L);
sigma_bounds = zeros(num_states,L);

% Initialize the filter:
sig_e = 1e-2;
sig_w = 1e-2;
sig_J = 1e-1;
P = diag([(sig_e^2)*ones(1,3), (sig_w^2)*ones(1,3), (sig_J^2)*ones(1,3)]);
Q = diag([1e-32*ones(1,3), 1e-8*ones(1,3), 0*ones(1,3)]); % Error in mean propagation

measurement_uncertainty = 2; %(error in pixels)

% Tuning parameters:
alpha = 1e-1;
beta = 20;
kappa = 3-9;

q_hat(:,1) = q0;
e0_hat = sig_e*randn(3,1);
w0_hat = w0 + sig_w*randn(3,1);
J_hat = diag(J) + sig_J.*randn(3,1);
X_hat(:,1) = [e0_hat; w0_hat; J_hat];
sigma_bounds(:,1) = sqrt(diag(P));


%% Simulate the images:
for ii = 1:L-1        
    % Generate Measurements:
    rotmat = Attitude.quat2rotmat(X(1:4,ii));
    lmks_i = rotmat*landmarks;
    [pixels, in_fov] = camera.PointsToPixels(lmks_i);
    
    pixels = pixels(:,in_fov) + measurement_uncertainty*randn(2,sum(in_fov));
    meas = [pixels(1,:), pixels(2,:)]';
    meas_avail = true;
    R = diag((measurement_uncertainty^2)*ones(size(meas)));
    
    % Simulate dynamics:
    X(:,ii+1) = rk4(@rotational_dynamics, dt, X(:,ii), J);
    
    % Run the UKF:
    dynamics_args = {};
    meas_args = {camera_ukf, landmarks(:,in_fov)};
    model_args = {dynamics_args, meas_args};
    [X_hat(:,ii+1), P, y_hat, q_hat(:,ii+1)] = ukf_attitude(@ukf_attitude_dynamics, @ukf_attitude_meas, X_hat(:,ii), dt,...
                                                            P, Q, R, meas_avail, meas,...
                                                            alpha, beta, kappa, model_args, q_hat(:,ii));
    sigma_bounds(:,ii+1) = sqrt(diag(P));
    
    % Draw the points and observations:
    if animate
        subplot(1,2,1)
        camera.Draw(1,'FaceColor',[1,.8,0],'EdgeColor',[.8,.6,0],...
                        'FaceAlpha',0.5); hold on
            if ii == 1
                lmks_plt = plot3(lmks_i(1,:),lmks_i(2,:),lmks_i(3,:),'.k');
                axis equal
                grid on
                rotate3d on
            else
                set(lmks_plt,'XData',lmks_i(1,:),...
                             'YData',lmks_i(2,:),...
                             'ZData',lmks_i(3,:));
            end
        subplot(1,2,2)
            if ii == 1
                pixels_plt = plot(pixels(1,:), pixels(2,:),'.k');
                axis equal
                xlim([0 camera.camera_model.resolution(1)])
                ylim([0 camera.camera_model.resolution(2)])
                set(gca, 'YDir','reverse'); %(Because image coordinates are up-side down)
            else
                set(pixels_plt, 'XData',pixels(1,:),...
                                'YData',pixels(2,:))
            end
        drawnow
    end
end

%% Plot the Results:
error_quat = zeros(size(q_hat));
for ii = 1:L
    error_quat(:,ii) = quat_error(q_hat(:,ii),X(1:4,ii));
end
angle_error = rad2deg(2*error_quat(1:3,:));
w_error = rad2deg(X(5:7,:) - X_hat(4:6,:));
J_error = X_hat(7:9,:) - diag(J);
sigma_bounds_plt = rad2deg(sigma_bounds);
t_plt = tspan;
XLAB = 'Time (sec)';

figure(1)
YLIM = 5;
subplot(3,1,1)
    plot(t_plt,angle_error(1,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(1,:));
    title('Attitude Error')
    ylabel('Roll (deg)')
    ylim([-1 1]*YLIM)
    grid on
subplot(3,1,2)
    plot(t_plt,angle_error(2,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(2,:));
    ylabel('Pitch (deg)')
    ylim([-1 1]*YLIM)
    grid on
subplot(3,1,3)
    plot(t_plt,angle_error(3,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(3,:));
    ylabel('Yaw (deg)')
    xlabel(XLAB)
    ylim([-1 1]*YLIM)
    grid on
    
figure(2)
YLIM = .15;
subplot(3,1,1)
    plot(t_plt,w_error(1,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(4,:));
    title('Angular Rate Error')
    ylabel('Roll (deg/s)')
    ylim([-1 1]*YLIM)
    grid on
subplot(3,1,2)
    plot(t_plt,w_error(2,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(5,:));
    ylabel('Pitch (deg/s)')
    ylim([-1 1]*YLIM)
    grid on
subplot(3,1,3)
    plot(t_plt,w_error(3,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(6,:));
    ylabel('Yaw (deg/s)')
    xlabel(XLAB)
    ylim([-1 1]*YLIM)
    grid on
    
figure(3)
subplot(3,1,1)
    plot(t_plt,J_error(1,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(7,:));
    title('J_{xx} Error')
    grid on
subplot(3,1,2)
    plot(t_plt,J_error(2,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(8,:));
    title('J_{yy} Error')
    grid on
subplot(3,1,3)
    plot(t_plt,J_error(3,:)); hold on
    drawBounds(t_plt,sigma_bounds_plt(9,:));
    title('J_{zz} Error')
    grid on