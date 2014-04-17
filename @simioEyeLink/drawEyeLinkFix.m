function drawEyeLinkFix(self)
            
    % Draw the black background
    Eyelink('Command',' clear_screen 0');
    
    % Draw a cross indicating subject center
    Eyelink('Command', 'draw_cross %d %d 10', ...
            self.env.displayCenter(1), ...
            self.env.displayCenter(2));
    
    % Draw the fixation window around the center
    Eyelink('Command', 'draw_box %d %d %d %d 15', ...
            self.env.displayCenter(1)-self.fixWindowRadius, ...
            self.env.displayCenter(2)-self.fixWindowRadius, ...
            self.env.displayCenter(1)+self.fixWindowRadius, ...
            self.env.displayCenter(2)+self.fixWindowRadius);
    
end