% Calibrate the EyeLink
function result = calibrate(self)
    % Calibrate the Eyelink
    result = self.doTrackerSetup('c');
    
    % Flush the key events from the buffer before resuming
    FlushEvents('keyDown');
    
    % Set the text color to white (255) after calibration
    Screen('TextColor', self.env.ptb.windowPtr, 255);
    
    % Start the recording
    Eyelink('StartRecording');
    
end