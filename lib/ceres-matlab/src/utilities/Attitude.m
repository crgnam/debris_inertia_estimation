classdef Attitude < handle
    % Attitude A class for handling all attitude/rotation computations
    
    properties (SetAccess = private)
        rotmat (3,3) % Rotation matrix representation of the attitude
    end
    
    methods
        function [self] = Attitude(format,varargin)
            % Creates an attitude object provided a specific input format
            %   A = Attitude('quaternion',[0;0;0;1]) creates an attitude
            %   object defined by the input shuster quaternion.
            %
            %   A = Attitude('RotationMatrix',eye(3)]) creates an attitude
            %   object defined by the input rotation matrix.
            %
            %   A = Attitude('EulerAngles','321',[30,45,20],true) creates
            %   an attitude object defined by a 3-2-1 euler angle sequence
            %   with angles of 30,45, and 20 degrees respectively
            %
            %   A = Attitude('EulerAngles','131',[1,pi,2],false) creates an
            %   attitude object defined by a 1-3-1 euler angle sequence
            %   with angles of 1, pi, and 2 radians
            %
            %   If 'EulerAngles' is the selected input type, after the
            %   angles are specified you can add an additional parameter of
            %   true so that the input angles are interpreted as degrees.
            %   Inputting false, or not inputing any final parameter, will
            %   default in the angles being interpreted as radians.
            
            self.setAttitude(format,varargin{:});
        end
    end

    methods (Access = public)
        function [] = setAttitude(self,format,varargin)
            % Changes the attitude of the already instantiated Attitude
            % object.  This accepts inputs of the exact same format as the
            % constructor.
            switch lower(format)
                case {'quaternion','quat'}
                    self.rotmat = self.quat2rotmat(varargin{1});
                case {'rotmat','rotationmatrix'}
                    self.rotmat = varargin{1};
                case {'euler','eulerangles'}
                    sequence = varargin{1};
                    assert(ischar(sequence) && length(sequence)==3,...
                           'A valid euler angle sequence must be provided (example: ''321'')')
                    angles = varargin{2};
                    self.rotmat = self.ea2rotmat(sequence,angles(1),angles(2),angles(3),varargin{3:end});
                case {'axisangle'}
                    axis = varargin{1};
                    angle = varargin{2};
                    self.rotmat = self.axisangle2rotmat(axis,angle,varargin{3:end});
            end
        end
        
        function [quat] = quaternion(self,type)
            % Returns a quaternion representation of the attitude.
            %
            % q = Attitude.quaternion() returns the quaternion
            % representation of the attitude in the shuster convention
            %
            % q = Attitude.quaternion('hamilton') returns the quaternion
            % representation of the attitude in the hamiltonian convention
            
            if nargin == 1
                type = 'shuster';
            end
            
            switch lower(type)
                case {'shuster'}
                    quat = self.rotmat2quat(self.rotmat);
                case {'hamilton','hamiltonian'}
                    quat = self.rotmat2quat(self.rotmat);
                    quat = [quat(4), quat(1:3)];
            end
        end
    end
    
    methods (Access = public)
        function [output] = mtimes(mat1,mat2)
            % This method allows for the multiplication of an attitude
            % object directly with another attitude object, matrix, or
            % vector.  If an attitude object is multiplied by another
            % attitude object, it will return a new attitude object.
            
            if isa(mat1,'Attitude') && isa(mat2,'Attitude')
                rotmat_new = mat1.rotmat*mat2.rotmat;
                output = Attitude('rotmat',rotmat_new);
            elseif isa(mat1,'Attitude')
                output = mat1.rotmat*mat2;
            elseif isa(mat2,'Attitude')
                output = mat1*mat2.rotmat;
            end
        end
        
        function [att_t] = ctranspose(att)
            % This method allows for the inverse rotation of the attitude
            % to be obtained by simply using the ' operator.
            
            att_t = Attitude('rotmat',eye(3));
            att_t.rotmat = att.rotmat';
        end
        
        function [att_t] = transpose(att)
            % This method allows for the inverse rotation of the attitude
            % to be obtained by simply using the ' operator.
            
            att_t = Attitude('rotmat',eye(3));
            att_t.rotmat = att.rotmat';
        end
    end
    
    methods (Access = public, Static)
        function [q] = rotmat2quat(R)
            % This method allows converting a rotation matrix into a
            % quaternion of the shuster convention.
            
            R1 = R(1,1);
            R2 = R(2,2);
            R3 = R(3,3);
            q = zeros(4,1);

            q(4) = sqrt(.25*(1+trace(R)));
            q(1) = sqrt(.25*(1+R1-R2-R3));
            q(2) = sqrt(.25*(1-R1+R2-R3));
            q(3) = sqrt(.25*(1-R1-R2+R3));

            qmax = max(q(q==real(q)));

            if qmax == q(1)
                q(1) = q(1);
                q(2) = (R(1,2)+R(2,1))/(4*q(1));
                q(3) = (R(3,1)+R(1,3))/(4*q(1));
                q(4) = (R(2,3)-R(3,2))/(4*q(1));

            elseif qmax == q(2)
                q(1) = (R(1,2)+R(2,1))/(4*q(2));
                q(2) = q(2);
                q(3) = (R(2,3)+R(3,2))/(4*q(2));
                q(4) = (R(3,1)-R(1,3))/(4*q(2));

            elseif qmax == q(3)
                q(1) = (R(3,1)+R(1,3))/(4*q(3));
                q(2) = (R(2,3)+R(3,2))/(4*q(3));
                q(3) = q(3);
                q(4) = (R(1,2)-R(2,1))/(4*q(3));

            elseif qmax == q(4)
                q(1) = (R(2,3)-R(3,2))/(4*q(4));
                q(2) = (R(3,1)-R(1,3))/(4*q(4));
                q(3) = (R(1,2)-R(2,1))/(4*q(4));
                q(4) = q(4);
            end
        end
        
        function [R] = quat2rotmat(q)
            % This method allows for a quaternion of the shuster convention
            % to be transformed into a rotation matrix.
            
            R = [q(1)^2-q(2)^2-q(3)^2+q(4)^2       2*(q(1)*q(2)+q(3)*q(4))         2*(q(1)*q(3)-q(2)*q(4));
                   2*(q(1)*q(2)-q(3)*q(4))      -q(1)^2+q(2)^2-q(3)^2+q(4)^2       2*(q(2)*q(3)+q(1)*q(4));
                   2*(q(1)*q(3)+q(2)*q(4))         2*(q(2)*q(3)-q(1)*q(4))      -q(1)^2-q(2)^2+q(3)^2+q(4)^2];
        end
        
        function [rotmat] = ea2rotmat(sequence, rot1,rot2,rot3, use_deg)
            % This function allows for a set of euler angles to be
            % converted to a rotation matrix.
            if nargin == 5
                assert(islogical(use_deg),'Input option for degrees must be a logical type')
                if use_deg
                    rot1 = deg2rad(rot1);
                    rot2 = deg2rad(rot2);
                    rot3 = deg2rad(rot3);
                end
            end

            if nargin == 3
                sequence = '321';
            end

            T{1} = @(rot1) [1       0            0;
                             0   cos(rot1)   sin(rot1);
                             0  -sin(rot1)   cos(rot1)];
            T{2} = @(rot2) [cos(rot2)  0  -sin(rot2);
                                 0     1       0;
                            sin(rot2)  0   cos(rot2)];
            T{3} = @(rot3) [ cos(rot3)   sin(rot3)  0;
                            -sin(rot3)   cos(rot3)  0;
                                 0           0      1];

            rotmat = T{str2double(sequence(3))}(rot3)*...
                     T{str2double(sequence(2))}(rot2)*...
                     T{str2double(sequence(1))}(rot1);
        end
        
        function [rotmat] = axisangle2rotmat(u,t,use_deg)
            if nargin == 3
                assert(islogical(use_deg),'Input option for degrees must be a logical type')
                if use_deg
                    t = deg2rad(t);
                end
            end
            x = u(1);
            y = u(2);
            z = u(3);
            c = cos(t);
            s = sin(t);
            rotmat = [ c+(x^2)*(1-c)   x*y*(1-c)-z*s   x*z*(1-c)+y*s;
                      y*x*(1-c)+z*s    c+(y^2)*(1-c)   y*z*(1-c)-x*s;
                      z*x*(1-c)-y*s    z*y*(1-c)+x*s   c+(z^2)*(1-c)];
        end
    end
end