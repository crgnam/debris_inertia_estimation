function [dq] = AttitudeKinematics(~,q,angular_rate)
    % Quaternion (Attitude) Kinematics:
    Bq = zeros(4,3);
    Bq(1:3,:) = cpm(q(1:3)) + diag([q(4), q(4), q(4)]);
    Bq(4,:) = -q(1:3);
    dq = (1/2)*Bq*angular_rate;
end