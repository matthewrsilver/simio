classdef simioEyeLink < dynamicprops
   
    properties
        
        % Handle back to simio
        env
        
        % Struct used by Psychtoolbox to talk to EyeLink
        settings

        timeOffset
        fixWindowRadius 
        trackedEyeNum
        eyePosBounds
        left  = 1;
        right = 2;

    end
    
    methods
        
        % Constructor for simioEyeLink
        function self = simioEyeLink(env)
           
            % Set basic properties 
            self.env             = env;
            self.eyePosBounds    = [env.display.width env.display.height];
            self.fixWindowRadius = env.deg2px(env.config.fixationWindowSize/2);
            
            % Set the tracked eye
            if strcmp(env.config.trackedEye, 'left')
                self.trackedEyeNum = self.left;
            elseif strcmp(env.config.trackedEye, 'right')
                self.trackedEyeNum = self.right;
            else
                disp('Error establishing tracked eye. Using right');
                self.trackedEyeNum = self.right;
            end

            % Psychtoolbox must be initialized first...
            if isempty(env.ptb)
                disp('Failed to initialize EyeLink: PTB uninitialized');
                return;
            end
            
            % Get a struct with EyeLink default values. 
            self.settings = EyelinkInitDefaults(env.ptb.windowPtr);
             
            % Adjust the appearance of the calibration targets
            self.settings.backgroundcolour        = env.config.backgroundColor;
            self.settings.foregroundcolour        = env.config.calibrationColor;
            self.settings.calibrationtargetcolour = env.config.calibrationColor;
            self.settings.calibrationtargetsize   = env.config.calibrationSize;
            self.settings.calibrationtargetwidth  = env.config.calibrationWidth;
            
            % Delete callback to trigger 'old' PTB calibration method
            self.settings.callback                = '';
            
            % Now actually initialize the EyeLink, quitting on failure
            if ~EyelinkInit(0, 1)                    
                disp('Failed to initialize EyeLink: Reason Unknown');
                return;
            end
            
            % Send a few configuration commands to EyeLink
            Eyelink('Command', 'link_sample_data = LEFT, RIGHT, GAZE, AREA');
            Eyelink('Command', 'clear_screen 0');
            Eyelink('Command', 'enable_automatic_calibration = NO');
            
            Eyelink('Command', 'generate_default_targets = NO');  
            Eyelink('Command', 'randomize_calibration_order = NO');  
            
            Eyelink('Command',                                               ...
                    'simulation_screen_distance = %d',                       ...
                    round(env.config.screenDistanceCm)*10);
            
            Eyelink('Command',                                               ...
                    'screen_phys_coords = %d, %d, %d, %d',                   ...
                    -10*env.config.screenWidthCm/2,                          ...
                    -10*env.config.screenHeightCm/2,                         ...
                     10*env.config.screenWidthCm/2,                          ...
                     10*env.config.screenHeightCm/2);
                
            Eyelink('Command',                                               ...
                    'screen_pixel_coords = 0, 0, %d, %d',                    ...
                    round(env.display.width)-1,                              ...
                    round(env.display.height)-1);
            
            % Set calibration target locations
            calDegrees   = env.config.calibrationEcc;
            calCoords    = [ 0  0;  0  1;  0 -1;                             ... 
                            -1  0;  1  0; -1  1;                             ...   
                             1  1; -1 -1;  1 -1];  
            numCalTargs  = size(calCoords, 1);
            calLocations = env.deg2px(calCoords*calDegrees);
            
            % Position those locations at the subject center
            calTargets   = calLocations +                                    ...
                           repmat(env.displayCenter, numCalTargs, 1);
            
            % And send these targets
            calPrintStr  = repmat('%d,%d ', 1, numCalTargs);
            Eyelink('Command',                                               ...
                    sprintf(['calibration_targets = ' calPrintStr],          ...
                    reshape(calTargets', [], 1)));
            
            % Now that we've got things configured in the EyeLink,
            % but before beginning calibration, etc, add a hook in
            % the main simio IO for fixation
            try
                self.env.io.addInterface('fixation', 'in', @(x)self.fixation);
                %self.env.io.addInterface('fixation', 'in', @(x)true);
            catch err
                disp(err.message);
            end
            
            % Prepare Eyelink screen to represent stimuli
            Eyelink('Command',' clear_screen 0');
            
            % Measure the time offset between Psychtoolbox time 
            % and EyeLink time
            Eyelink('Message', 'SYNCTIME');
            self.timeOffset = Eyelink('TimeOffset');
            self.env.sessionData.eyeLinkTimeOffset = self.timeOffset;

            
        end
        
        % Destructor for simioEyeLink
        function delete(self)
           
        end
        
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
        
        % Get the current eye position
        function eyePos = getEyePosition(self)
            
            % get the sample in the form of an event structure
            samp   = Eyelink('NewestFloatSample');
            eyePos = ceil([samp.gx(self.trackedEyeNum)    ...
                           samp.gy(self.trackedEyeNum)]);
            
            % clean up eye position to ensure it's within bounds. Minimum
            % value must be 1 because eyePos is used downstream as an array
            % index within a window ID map.
            eyePos = max(min(eyePos, self.eyePosBounds), 1);
            
        end
        
        % Get the current status of fixation, for use with simioIO
        function fixating = fixation(self)
            
            % Set default output to false
            fixating = false;
            
            % get the sample in the form of an event structure
            samp       = Eyelink('NewestFloatSample');
            curEyePos  = ceil([samp.gx(self.trackedEyeNum)    ...
                               samp.gy(self.trackedEyeNum)]);
            curEyeDist = norm(self.env.displayCenter - curEyePos);
                
            % Test the distance between the eye position and
            % the center
            if curEyeDist < self.fixWindowRadius
                fixating = true;
            end
                        
        end
        
        function fixating = gazeAt(self, location, diameter)
            
            fixating = false;
            
            % get the sample in the form of an event structure
            samp       = Eyelink('NewestFloatSample');
            curEyePos  = ceil([samp.gx(self.trackedEyeNum)    ...
                               samp.gy(self.trackedEyeNum)]);
            
            cuePosition = [self.env.displayCenter(1) + self.env.deg2px(location(1)), ...
                           self.env.displayCenter(2) + self.env.deg2px(location(2))];
                           
            curEyeDist = norm(cuePosition - curEyePos);
                
            % Test the distance between the eye position and
            % the center
            if curEyeDist < self.env.deg2px(diameter/2);
                fixating = true;
            end
            
        end
        
        function windowID = getGazeWindow(self, gazeWindowMap)
                      
            % Get the current eye position
            eyePos   = self.getEyePosition();
            
            % Return the window ID of the current eye position,
            % pulled from the gazeWindowMap
            windowID = gazeWindowMap(eyePos(1), eyePos(2));
            
        end
        
        function eyeLinkClear(self)
           
            Eyelink('Command',' clear_screen 0');
            
        end
        
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
        
    end
    
end