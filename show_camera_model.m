% This is just a quick script to visualize pinhole camera projection
matlabrc; clc; close all;
addpath(genpath('src'))
addpath(genpath('lib'))

% Draw the Target:
target = Spacecraft('blender/simple_rocket_body.obj',1);
target.Draw('FaceColor',[.5 .5 .5])
rotate3d on

focal_length = 3.6/1000;
sensor_size = 3.76/1000;
cam_model = PinholeModel('FocalLength',focal_length,'SensorSize',sensor_size);
camera = Camera('CameraModel',cam_model,'Parent2Self',Attitude.ea2rotmat('321', 0,-90,0, true));
camera.SetPose([2.5;0;0],Attitude.ea2rotmat('123', 90,180,0, true));
camera.Draw(1,'FaceColor',[.9 .7 .5],'EdgeColor',[.8 .6 .3],'FaceAlpha',0.5);

% Identify the visible vertices:
directions = normr(target.vertices - camera.position');
dotprod = sum(target.vertex_normals.*directions,2);
visible = dotprod < -cosd(75);

% Project the visible features:
pixels = camera.PointsToPixels(target.vertices(visible,:)');
pixels = pixels - camera.camera_model.resolution'/2;
pixels = pixels/camera.camera_model.resolution(1);
pixels = [pixels; zeros(1,size(pixels,2))];
pixels = camera.inertial2self'*pixels;
pixels = pixels + [1.5;0;0];
pixels(3,:) = -pixels(3,:);

% Transition the points:
[pixel_dirs, pixel_dist] = normc(pixels - target.vertices(visible,:)');

%% Create the Animation:
% Show the vertex normals:
L = 600;
v = VideoWriter('camera_projection.mp4','MPEG-4');
open(v)
for ii = 1:L
    % Show the vertices
    if ii < 100
        vertices_plt = plot3(target.vertices(:,1),target.vertices(:,2),target.vertices(:,3),'.k','MarkerSize',10);
    end
    
    % Show the vertex normals:
    if ii == 100
        target.DrawVertexNormals('m');
    end
    
    % Show the visible vertices:
    if ii >= 200 && ii < 300
        set(vertices_plt,'XData',target.vertices(visible,1),...
                         'YData',target.vertices(visible,2),...
                         'ZData',target.vertices(visible,3),...
                         'color','g');
    end
        
    % Show the projection:
    if ii >= 300 && ii < 400
        step_sizes = pixel_dist/(400-300);
        set(vertices_plt,'XData', target.vertices(visible,1)' + pixel_dirs(1,:).*(ii-300).*step_sizes,...
                         'YData', target.vertices(visible,2)' + pixel_dirs(2,:).*(ii-300).*step_sizes,...
                         'ZData', target.vertices(visible,3)' + pixel_dirs(3,:).*(ii-300).*step_sizes)
    end
    
    % Update the camera view:
    az = ii*(360/L)-90;
    view([az 20])
    if ii == 1
        DIM = 3;
        axis equal
        xlim([-1 1]*DIM)
        ylim([-1 1]*DIM)
        zlim([-1 1]*DIM)
        camva(3)
    end
    drawnow
    frame = getframe(gcf);
    writeVideo(v,frame);
end
close(v)