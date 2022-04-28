classdef RigidBody < handle
    % RigidBody A class for all rigid body type objects, and superclass to
    % CelestialBody and Spacecraft
    
    properties (SetAccess = private)
        % Basic parameters of a rigid body:
        position
        inertial2self
        mass
        inertia

        % Potential members:
        models
        components
    end
    
    methods
        function [self] = RigidBody(varargin)
            % Constructor for RigidBody
            validVector   = @(x) numel(x) == 3 && isnumeric(x);
            validScalar   = @(x) numel(x) == 1 && isnumeric(x);
            validMatrix   = @(x) all(size(x) == [3,3]) && isnumeric(x);
            validAttitude = @(x) isa(x,'Attitude') || validMatrix(x);
            validCell     = @(x) iscell(x);
            p = inputParser;
            p.KeepUnmatched = true;
                addOptional(p,'Position',[0;0;0],validVector);
                addOptional(p,'Attitude',eye(3),validAttitude);
                addOptional(p,'Mass',0,validScalar);
                addOptional(p,'Inertia',eye(3),validMatrix);
                addOptional(p,'Models',{},validCell);
                addOptional(p,'Components',{},validCell);
            parse(p,varargin{:});
            
            % Store input parameters:
            self.position     = p.Results.Position;
            self.inertial2self = p.Results.Attitude;
            self.mass         = p.Results.Mass;
            self.inertia      = p.Results.Inertia;

            % Store all member components:
            self.models = p.Results.Models;
            self.components = p.Results.Components;
            
            % Update shape model and landmarks according to the pose:
            self.setPose(self.position, self.inertial2self);
        end
    end
    
    methods (Access = public)
        function [] = setPose(self, position, inertial2self)
            % Method for setting the pose of the rigid body
            self.position = position;
            self.inertial2self = inertial2self;
            
            % Apply the pose to all of the models:
            for ii = 1:length(self.models)
                self.models{ii}.setPose(position, inertial2self);
            end
            
            % Apply the pose to all of the components:
            for ii = 1:length(self.components)
                self.components{ii}.setPose(position, inertial2self);
            end
        end
    end
    
    methods (Access = public)
        function [] = draw(self,varargin)
            self.shape_model.draw(varargin{:});
        end
        
        function [] = drawFaceNormals(self,varargin)
            self.shape_model.drawFaceNormals(varargin{:});
        end
        
        function [] = drawVertexNormals(self,varargin)
            self.shape_model.drawVertexNormals(varargin{:});
        end
    end
end