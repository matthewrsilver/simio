% Write text to the on screen display
function updateOSD(self, osdText)
    % Clear the osd portion of the display by drawing a rectangle
    Screen('FillRect',                  ...
        self.ptb.windowPtr,          ...
        self.config.osdBackgroundColor, ...
        self.osdRect);
                  
    % Iterate through the lines and draw them
    for line = 1:numel(osdText)
        Screen('DrawText', self.ptb.windowPtr, osdText{line}, 10, 20*(line-1));
    end
end