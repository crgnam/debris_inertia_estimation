function [dq] = q2dq(SIGMAS,q_hat_p)
    % Parameters:
    a_GRP = 1;
    f_GRP = 2*(a_GRP + 1);
    
    % equation 36
    q = zeros(4,size(SIGMAS,2));
    q(1,:) = -SIGMAS(4,:)*q_hat_p(1) - SIGMAS(3,:)*q_hat_p(2) + SIGMAS(2,:)*q_hat_p(3) + SIGMAS(1,:)*q_hat_p(4);
    q(2,:) = SIGMAS(3,:)*q_hat_p(1) - SIGMAS(4,:)*q_hat_p(2) - SIGMAS(1,:)*q_hat_p(3) + SIGMAS(2,:)*q_hat_p(4);
    q(3,:) = -SIGMAS(2,:)*q_hat_p(1) + SIGMAS(1,:)*q_hat_p(2) - SIGMAS(4,:)*q_hat_p(3) + SIGMAS(3,:)*q_hat_p(4);
    q(4,:) = SIGMAS(1,:)*q_hat_p(1) + SIGMAS(2,:)*q_hat_p(2) + SIGMAS(3,:)*q_hat_p(3) + SIGMAS(4,:)*q_hat_p(4);
    
    dq = f_GRP*[q(1,:);q(2,:);q(3,:)]./(a_GRP+[q(4,:);q(4,:);q(4,:)]);
end