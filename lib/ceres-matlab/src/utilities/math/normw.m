function [M,n] = normw(M)
    %@code{true}
    n = sqrt(sum(M.^2,3));
    M = bsxfun(@rdivide,M,n);
end