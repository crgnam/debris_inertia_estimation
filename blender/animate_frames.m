matlabrc; clc; close all;

v = VideoWriter('blender_animation_can.mp4','MPEG-4');
v.FrameRate = 5;
open(v)
frames = dir('renders/*.png');
for ii = 1:length(frames)
    frame_path = [frames(ii).folder, '\', frames(ii).name];
    img = imread(frame_path); %read the next image
    writeVideo(v,img); %write the image to file
end
close(v)