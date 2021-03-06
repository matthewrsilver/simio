function initWindow(self)
    % disable keyboard-in to Matlab; also speeds GetChar
    ListenChar(2);
    
    % Wait until all keys on keyboard are released:
    while KbCheck
        WaitSecs(0.1);
    end
    
    % get rid of all keys in buffer
    FlushEvents('keyDown');
    
    % Now initialize the window
    self.ptb.windowPtr = Screen('OpenWindow',             ...
                                self.config.screen,            ...
                                self.config.backgroundColor);
    
    % Set the text color to white (255). Must be after OpenWindow
    Screen('TextColor', self.ptb.windowPtr, 255);
    
    % EyeLink settings struct likes to have a pointer as well...
    self.eye.settings.window = self.ptb.windowPtr;
    
    % Can't have the cursor floating around while the task is running!
    HideCursor;
end
