function [gmst] = julianday2gmst(jd)
    %@code{true}
    t_ut1 = (jd - 2451545.0)/36525.0;

    gmst = -6.2e-6*t_ut1^3 + 0.093104*t_ut1^2 +...
           (876600.0*3600.0 + 8640184.812866)*t_ut1 + 67310.54841;

    gmst = rem(deg2rad(gmst)/240.0, 2*pi);

    if (gmst < 0)
        gmst = gmst + 2*pi;
    end
end

