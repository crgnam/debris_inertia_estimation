classdef Time < handle
    %@code{true}
    properties
        % Tracked for the simulation:
        dt %(sec)
        
        % Time tracked internally via julianday
        jd
    end
    
    %% Constructor
    methods
        function [self] = Time(time_system,start_time,dt)
            self.dt = dt;
            switch lower(time_system)
                case 'datetime'
                    self.jd = datetime2julianday(start_time);
                case 'julianday'
                    self.jd = start_time;
                case 'unix'
                    self.jd = unix2julianday(start_time);
                case 'gregorian'
                    self.jd = gregorian2julianday(start_time);
                case 'gmst'
                    error('GMST NOT YET IMPLEMENTED')
                otherwise
                    error(['The specified time_system must be one of the following: \n',...
                           'julianday | unix | gregorian | gmst'])
            end
        end
    end
    
    %% Public Methods
    methods (Access = public)
        function [] = update(self,dt)
            % If a new timestep has been provided, save it:
            if nargin == 2
                self.dt = dt;
            end
            
            % Update the julian day:
            self.jd = self.jd + self.dt/86400;
            
        end
        
        function [matlab_datetime] = datetime(self)
            matlab_datetime = julianday2datetime(self.jd);
        end
        
        function [u] = unix(self)
           u = julianday2unix(self.jd); 
        end
        
        function [greg] = gregorian(self)
            greg = julianday2gregorian(self.jd);
        end
    end
end