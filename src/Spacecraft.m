classdef Spacecraft < handle
    properties
        position
        attitude
        
        faces
        vertices_init
        vertices
        vertex_normals_init
        vertex_normals
        face_normals_init
        face_normals
        
        camera = []
        
        plot_handle = []
    end
    
    methods
        function [self] = Spacecraft(shape_model, scale)
            % Load the shape model:
            obj = readObj(shape_model);
            
            self.faces = obj.f.v;
            self.vertices_init = scale*obj.v;
            self.vertices = self.vertices_init;
            
            if size(obj.vn,1) == size(obj.v,1)
                self.vertex_normals_init = obj.vn;
            else
                self.CalculateNormals();
            end
            self.vertex_normals = self.vertex_normals_init;
        end
    end
    
    methods (Access = public)
        function [] = SetPose(self, position, attitude)
            % Update the vertex definitions:
            self.vertices = (attitude'*self.vertices_init')' + position';
            
            if ~isempty(self.camera)
                self.camera.SetPose(position,attitude);
            end
            
            % Update the stored states:
            self.position = position;
            self.attitude = attitude;
        end
        
        function [] = Draw(self, varargin)
            if isempty(self.plot_handle)
                self.plot_handle = patch('Faces',self.faces, 'Vertices',self.vertices, varargin{:}); hold on
                axis equal
                rotate3d on
            else
                set(self.plot_handle, 'Vertices',self.vertices);
            end
            
            if ~isempty(self.camera)
                self.camera.Draw(1,'FaceColor',[.9 .7 .5],'EdgeColor',[.8 .6 .3],'FaceAlpha',0.5);
            end
        end
        
        function [h] = DrawVertexNormals(self,varargin)
            h = quiver3(self.vertices(:,1),self.vertices(:,2),self.vertices(:,3),...
                        self.vertex_normals(:,1),self.vertex_normals(:,2),self.vertex_normals(:,3),varargin{:});
        end
        
        function [] = AddCamera(self, camera)
            self.camera = camera;
        end
    end
    
    methods (Access = private)
        function [] = CalculateNormals(self)
            if isempty(self.face_normals)
                mesh_struct.faces = self.faces;
                mesh_struct.vertices = self.vertices;
                self.face_normals_init = COMPUTE_mesh_normals(mesh_struct);
                self.face_normals = self.face_normals_init;
            end
            self.vertex_normals_init = STLVertexNormals(self.faces, self.vertices, self.face_normals);
        end
    end
end