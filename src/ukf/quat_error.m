function [error_quat] = quat_error(q1,q2)
    PSI = [q1(4)*eye(3)-cpm(q1(1:3)); -q1(1:3)'];
    
    error_quat = [PSI q1]*qinv(q2);
end

function [inv] = qinv(q)
    T = [-eye(3) zeros(3,1);
         zeros(1,3) 1];
    qstar = T*q;
    inv = qstar/norm(q)^2;
end