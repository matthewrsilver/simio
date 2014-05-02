function eyeLinkDraw(self, command, details)

    if ~exist('details', 'var'), details = ''; end

    switch command
        case 'clear'
            % Clear the eye link display
            Eyelink('Command',' clear_screen 0');

        case 'buffer'
            while numel(self.commandBuffer) > 0
                Eyelink('Command', self.commandBuffer{end});
                self.commandBuffer = self.commandBuffer{1:end-1};
            end
            self.eyeLinkCommandBuffer('clear');
          
            
        case 'fix'
             % Draw a cross indicating subject center
            Eyelink('Command', sprintf('draw_cross %d %d 10', self.env.displayCenter));
                
        case 'rect'
            % Draw a rectangle
            Eyelink('Command', sprintf('draw_box %d %d %d %d 15', details));
            
        case {'cross', 'cue'}
            % Draw a cross
            Eyelink('Command', sprintf('draw_cross %d %d 10', details));
            
        otherwise
            % Otherwise pass the command through
            Eyelink('Command', command)
    end

end