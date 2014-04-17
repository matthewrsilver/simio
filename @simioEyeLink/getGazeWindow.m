function windowID = getGazeWindow(self, gazeWindowMap)
                      
    % Get the current eye position
    eyePos   = self.getEyePosition();
    
    % Return the window ID of the current eye position,
    % pulled from the gazeWindowMap
    windowID = gazeWindowMap(eyePos(1), eyePos(2));
    
end