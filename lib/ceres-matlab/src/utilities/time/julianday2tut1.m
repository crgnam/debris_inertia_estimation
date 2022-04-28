function [t_ut1] = julianday2tut1(jd)
    %@code{true}
    t_ut1 = (jd - 2451545.0)/36525;
end