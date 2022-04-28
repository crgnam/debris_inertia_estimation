function [] = drawBounds(t,sig)
    FA = 0.2;
    
    % Draw the 3-sigma bounds above:
    a = area(t,[sig; sig; sig]'); hold on
    a(1).FaceColor = 'g';
    a(1).FaceAlpha = FA;
    a(1).EdgeColor = 'none';
    a(2).FaceColor = 'y';
    a(2).FaceAlpha = FA;
    a(2).EdgeColor = 'none';
    a(3).FaceColor = 'r';
    a(3).FaceAlpha = FA;
    a(3).EdgeColor = 'none';
    
    % Draw the 3-sigma bounds below:
    a = area(t,-[sig; sig; sig]');
    a(1).FaceColor = 'g';
    a(1).FaceAlpha = FA;
    a(1).EdgeColor = 'none';
    a(2).FaceColor = 'y';
    a(2).FaceAlpha = FA;
    a(2).EdgeColor = 'none';
    a(3).FaceColor = 'r';
    a(3).FaceAlpha = FA;
    a(3).EdgeColor = 'none';
end