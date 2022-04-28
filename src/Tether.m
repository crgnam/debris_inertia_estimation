classdef Tether < handle
    properties
        connection_body1
        connection1
        
        connection_body2
        connection2
        
        tension
        
        plot_handle = []
        LineWidth
    end
    
    methods
        function [self] = Tether(connection1, connection_body1, connection2, connection_body2)
            self.connection1 = connection1;
            self.connection_body1 = connection_body1;
            self.connection2 = connection2;
            self.connection_body2 = connection_body2;
            
        end
        
        function [] = Draw(self, varargin)
            % Calculate the two end-points:
            point1 = self.connection1.position + self.connection1.attitude'*self.connection_body1;
            point2 = self.connection2.position + self.connection2.attitude'*self.connection_body2;
            
            % Update the drawing:
            if isempty(self.plot_handle)
                self.plot_handle{1} = plot3([point1(1) point2(1)], [point1(2) point2(2)], [point1(3) point2(3)], varargin{:}); hold on
                self.LineWidth = self.plot_handle{1}.LineWidth;
                self.plot_handle{2} = plot3(point1(1), point1(2), point1(3), '.k', 'MarkerSize',self.LineWidth*2); hold on
                self.plot_handle{3} = plot3(point2(1), point2(2), point2(3), '.k', 'MarkerSize',self.LineWidth*2); hold on
                axis equal
                rotate3d on
            else
                set(self.plot_handle{1},'XData',[point1(1) point2(1)],...
                                        'YData',[point1(2) point2(2)],...
                                        'ZData',[point1(3) point2(3)]);
                set(self.plot_handle{2},'XData',point1(1),...
                                        'YData',point1(2),...
                                        'ZData',point1(3));
                set(self.plot_handle{3},'XData',point2(1),...
                                        'YData',point2(2),...
                                        'ZData',point2(3));
            end
        end
        
        function [] = SetTension(self, fraction)
            L = (1 + 2*fraction)*self.LineWidth;
            new_color = [fraction, 1-fraction, 0];
            set(self.plot_handle{1}, 'LineWidth', L)
            set(self.plot_handle{1},'color',new_color);
        end
    end
end