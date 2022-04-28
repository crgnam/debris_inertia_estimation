function [q] = e2q(phi, theta, psi, varargin)
    rotmat = eulerAnglesToRotation3d(phi, theta, psi, varargin{:});
    
    q = a2q(rotmat);
end