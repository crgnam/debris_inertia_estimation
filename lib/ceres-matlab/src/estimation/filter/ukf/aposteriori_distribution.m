function [P, deviations] = aposteriori_distribution(sigmas, mu, n, Wc, R)
    %@code{true}
    % Calculate the deviations:
    deviations = sigmas - mu(:,ones(1,n));
    
    % Recover distribution:
    P  = deviations*diag(Wc)*deviations' + R; 
end