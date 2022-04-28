function [scalar] = scalarProjection(a,b)
    %@code{true}
    scalar = dot(a,b/norm(b));
end