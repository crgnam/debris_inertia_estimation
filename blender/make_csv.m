matlabrc; clc; close all;

% Load the data from Derek's sim:
data = readmatrix('../data/SimStates.txt');
target_connection = data(:,7:9)';
position_chaser = data(:,10:12)';
position_target = data(:,13:15)';
angular_rate_chaser = data(:,16:18)';
angular_rate_target = data(:,19:21)';
quaternion_chaser = data(:,22:25)';
quaternion_target = data(:,26:29)';

% Take a picture every 5 seconds:
DOWN_SAMPLE = 5/0.1;

% Reformat the data into the form Blender can take:
t = zeros(1,size(data,1));
sat_position = position_target - position_chaser;

% Get the new attitude of the camera:
parent2cam = Attitude.ea2rotmat('321', 0,-90,0, true);
for ii = 1:size(quaternion_chaser,2)
    quaternion_chaser(:,ii) = a2q(parent2cam*q2a(quaternion_chaser(:,ii)));
end

% Save the data to csv:
output_data = [t; sat_position; quaternion_chaser; quaternion_target]';
output_data = output_data(1:DOWN_SAMPLE:end,:);
writematrix(output_data,'states.csv')