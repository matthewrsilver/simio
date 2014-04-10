classdef simioEyeLink < dynamicprops
    %SIMIOEYELINK 
    %   
   
    properties
        
        % Struct used by Psychtoolbox to talk to EyeLink
        settings
        
        % Handle back to simio
        env
        
        % Stored value of the offset from PTB time
        timeOffset
        fixWindowRadius 
        trackedEyeNum
        
        % constants
        left         = 1;
        right        = 2; 

    end
    
    methods
        
        % Constructor for simioEyeLink
        function self = simioEyeLink(env)
           
            self.env = env;
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
            
            % Get a struct with EyeLink defauly values. 
            self.settings = EyelinkInitDefaults(env.ptb.windowPtr);
             
            % Adjust the appearance of the calibration targets
            self.settings.backgroundcolour        = env.config.backgroundColor;
            self.settings.foregroundcolour        = env.config.calibrationColor;
            self.settings.calibrationtargetcolour = env.config.calibrationColor;
            self.settings.calibrationtargetsize   = env.config.calibrationSize;
            self.settings.calibrationtargetwidth  = env.config.calibrationWidth;
            
            % Delete callback to trigger old PTB calibration method
            self.settings.callback                = '';
            
            % Now actually initialize the EyeLink, quitting on failure
            if ~EyelinkInit(0, 1)                    
                disp('Failed to initialize EyeLink: Reason Unknown');
                return;
            end
            
            Eyelink('Command', 'link_sample_data = LEFT, RIGHT, GAZE, AREA');
            Eyelink('Command', 'clear_screen 0');
            Eyelink('Command', 'enable_automatic_calibration = NO');
            
            Eyelink('Command', 'generate_default_targets = NO');  
            Eyelink('Command', 'randomize_calibration_order = NO');  
            
            Eyelink('Command',                                          ...
                    'simulation_screen_distance = %d',                             ...
                    round(env.config.screenDistanceCm)*10);
            
            Eyelink('Command', ...
                    'screen_phys_coords = %d, %d, %d, %d', ...
                    -10*env.config.screenWidthCm/2,                   ...
                    -10*env.config.screenHeightCm/2,                  ...
                     10*env.config.screenWidthCm/2,                   ...
                     10*env.config.screenHeightCm/2);
                
            Eyelink('Command',                                          ...
                    'screen_pixel_coords = 0, 0, %d, %d',               ...
                    round(env.display.width)-1,                         ...
                    round(env.display.height)-1);
            
            % Set calibration target locations
            calDegrees   = env.config.calibrationEcc;
            calCoords    = [ 0  0;  0  1;  0 -1;   ... 
                            -1  0;  1  0; -1  1;   ...   
                             1  1; -1 -1;  1 -1];  
            numCalTargs  = size(calCoords, 1);
            calLocations = env.deg2px(calCoords*calDegrees);
            
            % Position those locations at the subject center
            calTargets   = calLocations +                               ...
                           repmat(env.displayCenter, numCalTargs, 1);
            
            % And send these targets
            calPrintStr  = repmat('%d,%d ', 1, numCalTargs);
            Eyelink('Command',                                          ...
                    sprintf(['calibration_targets = ' calPrintStr],     ...
                    reshape(calTargets', [], 1)));
            
            % Open a file in the Eyelink for saving data?
            %Eyelink('OpenFile', 'filename');
          

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
        
        function result = doTrackerSetup(self, sendkey)
            
            % Extract the settings
            el = self.settings;
            
            result=-1;
            if nargin < 1
                error( 'USAGE: result=EyelinkDoTrackerSetup(el [,sendkey])' );
            end
            
            % if we have the new callback code, we call it.
            if ~isempty(el.callback)
                if Eyelink('IsConnected') ~= el.notconnected
                    if ~isempty(el.window)
                        rect=Screen(el.window,'Rect');
                        % make sure we use the correct screen coordinates
                        Eyelink('Command', 'screen_pixel_coords = %d %d %d %d',rect(1),rect(2),rect(3)-1,rect(4)-1);
                    end
                else
                    return
                end
                result = Eyelink( 'StartSetup', 1 );
                
                return;
            end
            % else we continue with the old version
            
            
            Eyelink('Command', 'heuristic_filter = ON');
            Eyelink( 'StartSetup' );		% start setup mode
            Eyelink( 'WaitForModeReady', el.waitformodereadytime );  % time for mode change
            
            EyelinkClearCalDisplay(el);	% setup_cal_display()
            key=1;
            while key~= 0
                key=EyelinkGetKey(el);		% dump old keys
            end
            
            % go directly into a particular mode
            
            if nargin==2
                if el.allowlocalcontrol==1
                    switch lower(sendkey)
                        case{ 'c', 'v', 'd', el.ENTER_KEY}
                            %forcedkey=BITAND(sendkey(1,1),255);
                            forcedkey=double(sendkey(1,1));
                            Eyelink('SendKeyButton', forcedkey, 0, el.KB_PRESS );
                    end
                end
            end
            
            stop=0;
            while stop==0 && bitand(Eyelink( 'CurrentMode'), el.IN_SETUP_MODE)
                
                i=Eyelink( 'CurrentMode');
                
                if ~Eyelink( 'IsConnected' ) stop=1; break; end;
                
                if bitand(i, el.IN_TARGET_MODE)			% calibrate, validate, etc: show targets
                    %fprintf ('%s\n', 'dotrackersetup: in targetmodedisplay' );
                    self.targetModeDisplay();
                elseif bitand(i, el.IN_IMAGE_MODE)		% display image until we're back
                    % 		fprintf ('%s\n', 'EyelinkDoTrackerSetup: in ''ImageModeDisplay''' );
                    if Eyelink ('ImageModeDisplay')==el.TERMINATE_KEY
                        result=el.TERMINATE_KEY;
                        return;    % breakout key pressed
                    else
                        EyelinkClearCalDisplay(el);	% setup_cal_display()
                    end
                end
                
                [key, el]=EyelinkGetKey(el);		% getkey() HANDLE LOCAL KEY PRESS
                if false && key~=0 && key~=el.JUNK_KEY    % print pressed key codes and chars
                    fprintf('%d\t%s\n', key, char(key) );
                end
                
                
                switch key
                    case el.TERMINATE_KEY,				% breakout key code
                        result=el.TERMINATE_KEY;
                        return;
                    case { 0, el.JUNK_KEY }          % No or uninterpretable key
                    case el.ESC_KEY,
                        if Eyelink('IsConnected') == el.dummyconnected
                            stop=1; % instead of 'goto exit'
                        end
                        if el.allowlocalcontrol==1
                            Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
                        end
                    otherwise, 		% Echo to tracker for remote control
                        if el.allowlocalcontrol==1
                            Eyelink('SendKeyButton', double(key), 0, el.KB_PRESS );
                        end
                end
            end % while IN_SETUP_MODE
            
            % exit:
            EyelinkClearCalDisplay(el);	% exit_cal_display()
            result=0;
            return;
            
            
        end
        
        function result = targetModeDisplay(self)

            
            el = self.settings;
            
            result=-1; % initialize
            if nargin < 1
                error( 'USAGE: result=EyelinkTargetModeDisplay(el)' );
            end
            
            targetvisible = 0;	% target currently drawn
            targetrect=[0 0 0 0];
            
            tx=el.MISSING;
            ty=el.MISSING;
            
            otx=el.MISSING;    % current target position
            oty=el.MISSING;
            
            EyelinkClearCalDisplay(el);	% setup_cal_display()
            
            key=1;
            while key~= 0
                [key, el]=EyelinkGetKey(el);		% dump old keys
            end
            
             % Not sure why this is required, but detect when the target
             % is not visible (i.e. there are no targets left to present
             % during calibration), and send the escape signal
             % automatically.  Are there consequences for this??
            %[targetsRemain, ~, ~] = Eyelink( 'TargetCheck');
            % better solution, below....
            
            % LOOP WHILE WE ARE DISPLAYING TARGETS
            stop=0;
            while stop==0 && bitand(Eyelink('CurrentMode'), el.IN_TARGET_MODE)
                
                if Eyelink( 'IsConnected' )==el.notconnected
                    result=-1;
                    return;
                end;
                
                [key, el]=EyelinkGetKey(el);		% getkey() HANDLE LOCAL KEY PRESS
                
                switch key
                    case el.TERMINATE_KEY,       % breakout key code
                        EyelinkClearCalDisplay(el); % clear_cal_display();
                        result=el.TERMINATE_KEY;
                        return;
                    case el.SPACE_BAR,	         		% 32: accept fixation
                        if el.allowlocaltrigger==1
                            Eyelink( 'AcceptTrigger');
                            self.env.goodMonkey(2, 50, 30, self.env.codes.reward);
                        end
                        break;
                    case { 0,  el.JUNK_KEY	}	% No key
                    case el.ESC_KEY,
                        if Eyelink('IsConnected') == el.dummyconnected
                            stop=1;
                        end
                        if el.allowlocalcontrol==1
                            Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
                        end
                    otherwise,          % Echo to tracker for remote control
                        if el.allowlocalcontrol==1
                            Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
                        end
                end % switch key
                
                
                % HANDLE TARGET CHANGES
                [result, tx, ty]= Eyelink( 'TargetCheck');
                
                
                % erased or moved: erase target
                if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
                    EyelinkEraseCalTarget(el, targetrect);
                    targetvisible = 0;
                end
                % redraw if invisible
                if targetvisible==0 && result==1
                    % 		fprintf( 'Target drawn at: x=%d, y=%d\n', tx, ty );
                    
                    targetrect=EyelinkDrawCalTarget(el, tx, ty);
                    targetvisible = 1;
                    otx = tx;		% record position for future tests
                    oty = ty;
                    if el.targetbeep==1
                        EyelinkCalTargetBeep(el);	% optional beep to alert subject
                    end
                end
                
                % no target to begin with? quit
                %if targetvisible==0 && result==0
                %    Eyelink('SendKeyButton', el.ESC_KEY, 0, el.KB_PRESS );
                %end
                
                
            end % while IN_TARGET_MODE
            
            
            % exit:					% CLEAN UP ON EXIT
            if el.targetbeep==1
                if Eyelink('CalResult')==1  % does 1 signal success?
                    EyelinkCalDoneBeep(el, 1);
                else
                    EyelinkCalDoneBeep(el, -1);
                end
            end
            
            if targetvisible==1
                EyelinkEraseCalTarget(el, targetrect);   % erase target on exit, bit superfluous actually
            end
            EyelinkClearCalDisplay(el); % clear_cal_display();
            
            result=0;
            return;
            
        end
        
    end
    
end