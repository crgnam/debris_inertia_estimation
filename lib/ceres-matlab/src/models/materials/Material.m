classdef Material < handle
    properties
        texture Texture
        type char
    end
    
    methods
        function [self] = Material(varargin)
            % Parse the inputs:
            validTexture = @(x) isa(x,'Texture');
            p = inputParser;
                addOptional(p,'Texture',Texture([0.5 0.5 0.5]),validTexture);
            parse(p,varargin{:});
            
            % Store the inputs:
            self.texture = p.Results.Texture;
        end
    end
    
    methods (Abstract)
        [bounced_ray] = bounceRay(self,intersection,ray,normal)
        [illum] = shader(self,tri,V,N,L,I)
    end      
end