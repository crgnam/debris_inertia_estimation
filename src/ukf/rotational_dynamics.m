function [dX] = rotational_dynamics(~,X,J)
    % Angular rates:
    q = X(1:4);
    w = X(5:7);

    % Calculate Angular Momentums:
    h_sat = J*w;

    % Euler's Rotational Equations:
    dw = J\cross(-w, h_sat);

    % Quaternion (Attitude) Kinematics:
    Bq = zeros(4,3);
    Bq(1:3,:) = cpm(q(1:3)) + diag([q(4), q(4), q(4)]);
    Bq(4,:) = -q(1:3);
    dq = (1/2)*Bq*w;

    % Form differential state vector:
    dX = [dq; dw];
end