function [T, rRSW, vRSW] = eci2rsw(rECI, vECI)
    %@code{true}
    rvec = rECI/norm(rECI);
    wvec = cross(rECI, vECI)/norm(cross(rECI, vECI));
    svec = cross(wvec, rvec)/norm(cross(wvec, rvec));

    T = [rvec'; svec'; wvec'];

    rRSW = T*rECI;
    vRSW = T*vECI;
end

