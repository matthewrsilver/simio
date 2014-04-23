% Initialize Psychtoolbox
function initializePsychtoolbox(self)

    % Extract information about screens
    self.display       = Screen('Resolution', self.config.screen);
    pxPerCmWidth       = self.display.width/self.config.screenWidthCm;
    pxPerCmHeight      = self.display.height/self.config.screenHeightCm;
    self.pxPerCm       = mean([pxPerCmWidth pxPerCmHeight]);
    
    % Warn if pixels aren't square (based on measurements)
    if abs(pxPerCmWidth-pxPerCmHeight) > .1
        disp('WARNING: Pixels not square. Measure monitor in cm.')
    end
    
    % Find the center of the screen from the subject perspective
    eyeCenterYCm       =   self.config.screenHeightCm     ...
                         + self.config.screenElevationCm  ...
                         - self.config.eyeElevationCm;
    eyeCenterX         = round(self.display.width/2);
    eyeCenterY         = round(eyeCenterYCm*self.pxPerCm);
    self.displayCenter = [eyeCenterX eyeCenterY]; 
    
    % Prepare to write text using the fastest renderer
    Screen('Preference', 'TextRenderer',    0);
    Screen('Preference', 'DefaultFontSize', 14);
    
    % Specify a key name map.  PTB says to do this
    KbName('UnifyKeyNames');
    
    % disable keyboard-in to Matlab; also speeds GetChar
    ListenChar(2);
    
    % Wait until all keys on keyboard are released:
    while KbCheck
        WaitSecs(0.1);
    end
    
    % get rid of all keys in buffer
    FlushEvents('keyDown');
    
    % Now initialize the window
    self.ptb.windowPtr = Screen('OpenWindow',                  ...
                                self.config.screen,            ...
                                self.config.backgroundColor);
    
    HideCursor;
    
    % Set the text color to white (255)
    Screen('TextColor', self.ptb.windowPtr, 255);
    
    % Set up other psychtoolbox stuff
    self.ptb.textures = containers.Map('KeyType',   'int32',   ... 
                                       'ValueType', 'any');
    
end
