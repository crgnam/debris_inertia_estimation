classdef Spheres < handle
    properties
        origins
        radii
        shell
        
        num_spheres
    end
    
    methods
        function [self] = Spheres(origins,radii,varargin)
            % Constructor for Spheres object, representing a colleciton of
            % perfect spheres
            
            % Parse the inputs:
            validShell = @(x) islogical(x);
            p = inputParser;
                addParameter(p,'Shell',false,validShell);
            parse(p,varargin{:});
            
            self.num_spheres = size(origins,1);
            if numel(radii) == 1
                radii = radii*ones(self.num_spheres,1);
            end
            
            self.origins = origins;
            self.radii = radii;
            self.shell = p.Results.Shell;
        end
    end
    
    methods (Access = public)
        function [] = draw(self,varargin)
            if numel(self.shell) == 1 && all(self.shell == false)
                error('DRAWING WITH NO DEFINED SHELL IS NOT YET IMPLEMENTED')
            else
                h = gobjects(sum(self.shell),1);
                iter = 1;
                for ii = 1:size(self.origins,1)
                    if self.shell(ii)
                        h(iter) = drawSphere([self.origins(ii,:),self.radii(ii)],'nPhi',16,'nTheta',8,varargin{:}); hold on
                        iter = iter+1;
                    end
                end
            end
            axis equal
            rotate3d on
        end
    end
end