classdef Cubes < handle
    properties
        origins
        dimensions
        shell
        
        num_cubes
    end
    
    methods
        function [self] = Cubes(origins,dimensions,varargin)
            % Constructor for Cubes object, representing a colleciton of
            % perfect cubes
            
            % Parse the inputs:
            validShell = @(x) islogical(x);
            p = inputParser;
                addParameter(p,'Shell',false,validShell);
            parse(p,varargin{:});
            
            self.num_cubes = size(origins,1);
            if numel(dimensions) == 1
                dimensions = dimensions*ones(self.num_cubes,1);
            end
            
            self.origins = origins;
            self.dimensions = dimensions;
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
                for ii = 1: size(self.origins,1)
                    if self.shell(ii)
                        h(iter) = drawCube([self.origins(ii,:),self.dimensions(ii)],varargin{:}); hold on
                        iter = iter+1;
                    end
                end
            end
            axis equal
            rotate3d on 
        end
    end
end