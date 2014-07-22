function eyeLinkDraw(self, command, details)

    % If there's no Eyelink, stop right now.
    if ~self.eye.connected, return; end;

    if ~exist('details', 'var'), details = ''; end
    
    switch command
        case 'clear'
            % Clear the eye link display
            Eyelink('Command','clear_screen 0');

        case 'buffer'
            while numel(self.eye.commandBuffer) > 0
                Eyelink('Command', self.eye.commandBuffer{end});
                self.eye.commandBuffer = self.eye.commandBuffer(1:end-1);
            end
            self.eyeLinkCommandBuffer('clear');
          
            
        case 'fix'
             % Draw a cross indicating subject center
            Eyelink('Command', sprintf('draw_cross %d %d 10', self.displayCenter));
                
        case 'rect'
            % Draw a rectangle
            Eyelink('Command', sprintf('draw_box %d %d %d %d 15', details));
            
        case {'circ', 'circle'}
            % Draw an octagon to serve as a circle
            n = 8;
            
            % Pull info from details:
            r = details(1);
            
            if numel(details) >= 3
                cX = details(2);
                cY = details(3);
            else
                cX = self.displayCenter(1);
                cY = self.displayCenter(2);
            end
            
            % Start by generating coordinates for lines...
            a = tan(pi/n)*r;
            x = [r  a -a -r -r -a  a  r  r] + cX;
            y = [a  r  r  a -a -r -r -a  a] + cY;
            
            for cmd = 1:n
                Eyelink('Command', sprintf('draw_line %d %d %d %d 10', [x(cmd) y(cmd) x(cmd+1) y(cmd+1)]));
            end
            
        case {'cross', 'cue'}
            % Draw a cross
            Eyelink('Command', sprintf('draw_cross %d %d 10', details));
            
        otherwise
            % Otherwise pass the command through
            Eyelink('Command', command)
    end

end