function [meas] = ukf_attitude_meas(~, X, camera, landmarks)
    % Apply estimated attitude to the known landmark positions:
    rotmat = Attitude.quat2rotmat(X(1:4));
    lmks_i = rotmat*landmarks;
    
    % Generate the predicted measurement:
    [pixels,~] = camera.PointsToPixels(lmks_i);
    meas = [pixels(1,:),pixels(2,:)]';
end