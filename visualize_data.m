% This is just a quick script to visualize the dynamics
matlabrc; clc; close all
addpath(genpath('src'))
addpath(genpath('lib'))

% Load the data:
data = readmatrix('data/SimStates.txt');

% Extract the data:
dt = 0.1;
tension_vector = data(:,1:3)';
J_xyz = data(:,4:6)';
target_connection = data(:,7:9)';
position_chaser = data(:,10:12)';
position_target = data(:,13:15)';
angular_rate_chaser = data(:,16:18)';
angular_rate_target = data(:,19:21)';
quaternion_chaser = data(:,22:25)';
quaternion_target = data(:,26:29)';

[~,tension_magnitude] = normc(tension_vector);

% Create the objects:
chaser = Spacecraft('blender/simple_spacecraft_body.obj',1/2);
target = Spacecraft('blender/simple_rocket_body.obj',1);
tether = Tether(chaser,[0;0;0], target,target_connection);

% Create a camera model:
focal_length = 3.6/1000;
sensor_size = 3.76/1000;
cam_model = PinholeModel('FocalLength',focal_length,'SensorSize',sensor_size);
camera = Camera('CameraModel',cam_model,'Parent2Self',Attitude.ea2rotmat('321', 0,-90,0, true));
chaser.AddCamera(camera);

% Visualize the data:
v = VideoWriter('dynamics_bottom.mp4','MPEG-4');
open(v)
for ii = 1:5:3000
    % Update the positions of objects:
    chaser.SetPose(position_chaser(:,ii), q2a(quaternion_chaser(:,ii)));
    target.SetPose(position_target(:,ii), q2a(quaternion_target(:,ii)));
    
    % Update the drawing:
    chaser.Draw('FaceColor',[.5 .5 .5],'EdgeColor','none');
    target.Draw('FaceColor',[.5 .5 .5],'EdgeColor','none');
    tether.Draw('LineWidth',1,'Color','g');
    if ii == 1
        light('Position',[1e9 5e8 0],'Style','local')
%         view([130 60])
        view([-50,-47])
        camva(3)
    end
    
    % Change the tether color based on the tension magnitude:
    tension_scale = min([1, norm(tension_vector(:,ii))/mean(tension_magnitude)]);
    tether.SetTension(tension_scale);
    drawnow
%     pause(1/30)
    frame = getframe(gcf);
    writeVideo(v,frame);
end
close(v)