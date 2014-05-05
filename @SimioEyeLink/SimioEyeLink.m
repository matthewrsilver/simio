classdef SimioEyeLink < dynamicprops & handle
   
    properties
        
        % Struct that holds EyeLink data 
        eye
        
        % Struct used by Psychtoolbox to talk to EyeLink
        %settings

        %commandBuffer = {};
        
        %timeOffset
        %fixWindowRadius 
        %trackedEyeNum
        %eyePosBounds
        %left  = 1;
        %right = 2;

    end
    
    methods
        
        % Constructor for SimioEyeLink
        function self = SimioEyeLink(config)
           
            % Set basic properties 
            self.eye.eyePosBounds    = [self.display.width self.display.height];
            self.eye.fixWindowRadius = self.deg2px(config.fixationWindowSize/2);
            self.eye.commandBuffer   = {};
            
            % Set the tracked eye
            if strcmp(config.trackedEye, 'left')
                self.eye.trackedEyeNum = 1;%self.left;
            elseif strcmp(config.trackedEye, 'right')
                self.eye.trackedEyeNum = 2;%self.right;
            else
                disp('Error establishing tracked eye. Using right');
                self.eye.trackedEyeNum = 2;%self.right;
            end

            % Psychtoolbox must be initialized first...
            %if isempty(env.ptb)
            %    disp('Failed to initialize EyeLink: PTB uninitialized');
            %    return;
            %end
            
            % Get a struct with EyeLink default values. 
            self.eye.settings = EyelinkInitDefaults(self.ptb.windowPtr);
             
            % Adjust the appearance of the calibration targets
            self.eye.settings.backgroundcolour        = config.backgroundColor;
            self.eye.settings.foregroundcolour        = config.calibrationColor;
            self.eye.settings.calibrationtargetcolour = config.calibrationColor;
            self.eye.settings.calibrationtargetsize   = config.calibrationSize;
            self.eye.settings.calibrationtargetwidth  = config.calibrationWidth;
            
            % Delete callback to trigger 'old' PTB calibration method
            self.eye.settings.callback                = '';
            
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
                    round(config.screenDistanceCm)*10);
            
            Eyelink('Command',                                               ...
                    'screen_phys_coords = %d, %d, %d, %d',                   ...
                    -10*config.screenWidthCm/2,                          ...
                    -10*config.screenHeightCm/2,                         ...
                     10*config.screenWidthCm/2,                          ...
                     10*config.screenHeightCm/2);
                
            Eyelink('Command',                                               ...
                    'screen_pixel_coords = 0, 0, %d, %d',                    ...
                    round(self.display.width)-1,                              ...
                    round(self.display.height)-1);
            
            % Set calibration target locations
            calDegrees   = config.calibrationEcc;
            calCoords    = [ 0  0;  0  1;  0 -1;                             ... 
                            -1  0;  1  0; -1  1;                             ...   
                             1  1; -1 -1;  1 -1];  
            numCalTargs  = size(calCoords, 1);
            calLocations = self.deg2px(calCoords*calDegrees);
            
            % Position those locations at the subject center
            calTargets   = calLocations +                                    ...
                           repmat(self.displayCenter, numCalTargs, 1);
            
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
            self.eye.timeOffset = Eyelink('TimeOffset');
            self.sessionData.eyeLinkTimeOffset = self.eye.timeOffset;

            
        end
        
        % Destructor for simioEyeLink
        function delete(self)
           
        end
             
    end
    
end