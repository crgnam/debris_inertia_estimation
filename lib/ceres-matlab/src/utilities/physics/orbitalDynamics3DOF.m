function [dX] = orbitalDynamics3DOF(~,X, models)
    % Get all of the accelerations
    accel = zeros(3,1);
    for ii = 1:length(models)
        accel = accel + models{ii}.getAcceleration(X);
    end

    % Form the differential state:
    dX = [X(4:6); accel];
end