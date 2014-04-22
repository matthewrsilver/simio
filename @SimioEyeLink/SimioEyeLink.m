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
             
    end
    
end