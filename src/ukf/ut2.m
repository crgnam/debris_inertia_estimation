function [mu, P, deviations, sigmas_out, q_hat_p] = ut2(systemModel, dt, sigmas, Wm, Wc, R, varargin)
    num_sigmas = size(sigmas,2);
    sigmas_out = zeros(size(sigmas));
    
    % Propagate sigma points through dynamics:
    for ii = 1:num_sigmas
        sigmas_out(:,ii) = systemModel(dt, sigmas(:,ii), varargin{:});
    end
    
    % Reform the error vector:
    q_hat_p = sigmas_out(1:4,1);
    dq = q2dq(sigmas_out,q_hat_p);
    sigmas_out = [dq; sigmas_out(5:7,:)];
    
    % Calculate new mean:
    mu = sigmas_out*Wm'; 
    
    % Recover a posteriori distribution:
    [P, deviations] = aposteriori_distribution(sigmas_out, mu, num_sigmas, Wc, R);
end