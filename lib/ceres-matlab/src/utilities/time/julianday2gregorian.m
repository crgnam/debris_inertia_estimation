function [gregorian] = julianday2gregorian(jd)
    %@code{true}
    t_1900 = (jd - 2415019.5)/365.25;
    year = 1900 + floor(t_1900);
    leapYears = floor((year-1900-1)/4);
    days = (jd - 2415019.5) - ((year-1900)*365 + leapYears);

    if days < 1.0
        year = year - 1;
        leapYears = floor( (year-1900-1)/4 );
        days = (jd - 2415019.5) - ((year-1900)*365 + leapYears);
    end

    LMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if mod(year, 4) == 0
        LMonth(2) = 29;
    end

    dayOfYear = floor(days);
    daySum = 0;
    monthFound = false;
    month = 0;
    day = 0;
    for i = 1:11
        daySum = daySum + LMonth(i);
        if ((daySum+1) > dayOfYear) && (monthFound == false)
            month = i;
            day = dayOfYear - sum( LMonth(1:i-1) );
            monthFound = true;
        end
    end

    tau = (days - dayOfYear)*24;
    hour = floor( tau );
    minute = floor( (tau-hour)*60 );
    second = (tau - hour - minute/60)*3600;

    % Compile Results into output
    gregorian = [year, month, day, hour, minute, second];
end