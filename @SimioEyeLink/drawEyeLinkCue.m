function drawEyeLinkCue(self, location, diameter)
    
    if ~exist('diameter', 'var'), diameter = self.env.config.cueWindowSize; end
    
    cueLocation = [self.env.displayCenter(1) + self.env.deg2px(location(1)), ...
                   self.env.displayCenter(2) + self.env.deg2px(location(2))];
    
    cueWindowRadius = self.env.deg2px(diameter/2);
    
    % Draw a cross indicating subject center
    Eyelink('Command', 'draw_cross %d %d 10', ...
            cueLocation(1), cueLocation(2));
    
    % Draw the fixation window around the center
    Eyelink('Command', 'draw_box %d %d %d %d 15', ...
            cueLocation(1)-cueWindowRadius, ...
            cueLocation(2)-cueWindowRadius, ...
            cueLocation(1)+cueWindowRadius, ...
            cueLocation(2)+cueWindowRadius);
    
end