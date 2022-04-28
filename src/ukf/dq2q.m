function [q] = dq2q(dq,q_prev)
    % Generalized Parameters:
    a_GRP = 1;
    f_GRP = 2*(a_GRP + 1);
    
    sig_pt_norm_square = dq(1,:).^2 + dq(2,:).^2 + dq(3,:).^2;
    
    % Eq33: to calculate error quaternions :
    dq4 = (-a_GRP*sig_pt_norm_square + f_GRP*(f_GRP^2 + (1-a_GRP^2)*sig_pt_norm_square).^0.5)./(f_GRP^2 + sig_pt_norm_square);
    dq1 = (a_GRP + dq4).*dq(1,:)/f_GRP;
    dq2 = (a_GRP + dq4).*dq(2,:)/f_GRP;
    dq3 = (a_GRP + dq4).*dq(3,:)/f_GRP;
    
    % Eq32: to calcuate sigma point quaternions from the error quaternions 
    q = zeros(4,size(dq,2));
    q(1,:) = dq4*q_prev(1) +  dq3*q_prev(2) - dq2*q_prev(3) + dq1*q_prev(4);
    q(2,:) = -dq3*q_prev(1) + dq4*q_prev(2) + dq1*q_prev(3) + dq2*q_prev(4);
    q(3,:) = dq2*q_prev(1) - dq1*q_prev(2) + dq4*q_prev(3)  + dq3*q_prev(4);
    q(4,:) = -dq1*q_prev(1) - dq2*q_prev(2) - dq3*q_prev(3) + dq4*q_prev(4);
end