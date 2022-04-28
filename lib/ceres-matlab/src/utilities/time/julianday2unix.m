function [unix] = julianday2unix(jd)
    %@code{true}
    unix = (jd - 2440587.5)*86400;
end