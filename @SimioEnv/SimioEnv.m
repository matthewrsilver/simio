classdef SimioEnv < handle
%SIMIOENV Environment for monkey training
%   Simio has three essential functions. To detect external events such
%   as lever presses and eye movements though a DAQ and through
%   ethernet, to display stimuli on the screen using PsychToolbox, and
%   to mark important times with event codes through the DAQ.
    
    properties
        
        % simioIO object, with hooks to IO interfaces in DAQ and EyeLink
        io

        % simioDAQ object
        daq
        
        % simioEyeLink object
        eye
        
        % Psychtoolbox information
        ptb
                        
        % Display information
        display
        displayCenter
        pxPerCm
        osdRect
        taskRect
        
        % Structs to store session and trial information
        sessionData
        currentTrial
        
        % Configuration information (defaults)
        config = struct(                        ...
            'itiDuration',       2000,          ...
            'experimentName',    'experiment',  ...
            'subjectName',       'subject',     ...
            'osdHeight',         200,           ...
            'backgroundColor',   [0   0   0],   ...
            'osdBackgroundColor',[0   0   0],   ...
            'fixationPointColor',[255 255 255], ...
            'fixationWindowSize',4,             ...
            'calibrationColor',  [255 255 255], ...
            'calibrationSize',   1,             ...
            'calibrationWidth',  .5,            ...
            'calibrationEcc',    6,             ...
            'cueColor',          [255 255 255], ...
            'trackedEye',        'right',       ...
            'dataPath',          '.',           ...
            'fileName',          '',            ...
            'screen',            0,             ...
            'screenDistanceCm',  47,            ...
            'screenWidthCm',     37.4,          ...
            'screenHeightCm',    30,            ...
            'screenElevationCm', 61,            ... 
            'eyeElevationCm',    73,            ...
            'daqAdaptor',        'nidaq',       ...
            'daqID',             'Dev1');
        
        % Event codes (defaults)
        codes = struct(           ...
            'correct',       0,   ...
            'beginITI',      16,  ...
            'endITI',        17,  ...
            'beginTrial',    10,  ...
            'endTrial',      11,  ...
            'reward',        26,  ...
            'displayUpdate', 27,  ...
            'screenClear',   28);
    end
    
    methods
        
        % Constructor for the simio class
        function self = SimioEnv(varargin)
           
            % First thing: shuffle the random number generator
            try
                rng('shuffle');
            catch err
                % Roll back to earlier, ugly syntax. Should be the
                % same (grabbed mostly from rng code) but not 
                % certain, so display message...
                disp('WARNING: Using old random number generation')
                s = RandStream('mt19937ar', 'Seed', sum(100*clock));
                RandStream.setDefaultStream(s);
            end
            
            % Extract and store configuration information
            for arg = 1:2:numel(varargin)
                switch varargin{arg}
                    case 'config'
                        self.userConfig(varargin{arg+1});
                    case 'codes'
                        self.userCodes(varargin{arg+1});
                    otherwise
                        disp([varargin{arg} ' is not a valid parameter']);
                end
            end
            
            % Using the configuration information, generate a file name
            self.generateUniqueFileName();
            
            % Initialize the sessionData structure
            self.initializeSessionData();
            
            % Initialize the currentTrial structure 
            self.newTrial(0);
            
            % Initialize simioIO object
            disp('Initializing Simio IO Interface...');
            self.io  = SimioIO(self);

            % Initialize simioDAQ object
            disp('Initializing Simio DAQ...');
            self.daq = SimioDAQ(self);

            % Initialize Psychtoolbox
            disp('Initializing Simio Psychtoolbox...');
            self.initializePsychtoolbox();
                
            % Set rects for osd and task area, now that all is known
            self.osdRect  = [0                  0                       ...
                             self.display.width self.config.osdHeight];
                         
            self.taskRect = [0                  self.config.osdHeight   ...
                             self.display.width self.display.height];
            	    
            % Initialize the simioEyeLink object
            if self.config.useEyeLink
                self.eye = SimioEyeLink(self);
            end
                
        end
        
        % Desctructor for the simio class
        function delete(self)

            % Delete the daq, shutting down the engine.
            %delete(self.daq);

            % Reenable the keyboard
            ListenChar(1);
                        
            % Close the psychtoolbox screens
            Screen('CloseAll');
            
        end
        
        % Begin a trial loop, executing function handles pre, during, post
        function sd = runSession(self, preTrial, trial, postTrial, varargin)
            
            % %%%%%%%%%%%%%% PREPARE TO BEGIN THE SESSION %%%%%%%%%%%%%% %
            
            % Set various initial values
            self.sessionData.config        = self.config;
            self.sessionData.codes         = self.codes;
            self.sessionData.startDateTime = now;
            self.sessionData.startTime     = GetSecs;
            beginITI                       = self.sessionData.startTime;
            showMenu                       = 1;
            self.strobeCodes(self.codes.beginITI);
    
            % Loop through trials....
            for trialNum = 1:intmax
    
                % %%%%%%%%%%%% BEGIN THE TRIAL WITH THE MENU %%%%%%%%%%%% %
                
                quit = 0;    
                % Check to see if the escape key has been pressed
                
                % THIS IS UNCLEAN (showMenu, CharAvail, etc) MUST FIX
                
                while CharAvail || (trialNum == 1 && showMenu)
                    if  showMenu || (uint16(GetChar(1)) == KbName('ESCAPE'))
                    
                        % If so, bring up the menu on the OSD, and get the
                        % output. At the moment, the output is simply a logical
                        % value that indicates whether the user has instructed
                        % the system to quit. 
                        quit = self.osdMenu();
                        showMenu = 0;
                    end
                end
                % Quit if requested...
                if quit
                    trialNum = trialNum-1; %#ok
                    break; 
                end
                
                
                % %%%%%%%%%%%% PREPARE FOR THE TRIAL IN ITI %%%%%%%%%%%% %
    
                % Start by clearing trial information
                self.newTrial(trialNum);
        
                % Run the pretrial function passed as an argument
                preTrial(self, varargin{:});
                
                % Update the OSD now that the trial is prepared
                self.updateOSD(self.currentTrial.osdText);
                self.flip(self.codes.displayUpdate);
                
                % Having prepared the trial, wait for rest of ITI
                self.wait(self.config.itiDuration - (GetSecs - beginITI));
        
                % %%%%%%%%%%%%%%%%%%%% RUN THE TRIAL %%%%%%%%%%%%%%%%%%% %
                
                % Run the trial
                self.strobeCodes(self.codes.endITI);
                self.strobeCodes(self.codes.beginTrial,3);
                self.currentTrial.startTime = GetSecs;
                trial(self, varargin{:});

                % After the trial, ensure that the screen is clear
                self.clearScreen();
                self.flip(self.codes.screenClear);
        
                % %%%%%%%%%%%%% BEGIN ITI; POST TRIAL; MENU %%%%%%%%%%%% %
                
                % End the trial properly and begin the ITI
                self.strobeCodes(self.codes.endTrial, 3);
                beginITI = self.strobeCodes(self.codes.beginITI);
 
                % Store trial information in sessionData
                self.storeTrialData();
                
                % While we're waiting in the ITI, run the postTrial
                % script. This is a good time to do bookkeeping...
                postTrial(self, varargin{:});
                
                % Save session data to "disk" as a precaution against
                % unexpected session end
                self.saveSessionData();
                
            % Begin next trial......    
            end

            
            % %%%%%%%%%%%% WRAP UP SESSION; SAVE DATA, ETC. %%%%%%%%%%%% %

            % If we're here, that means that the loop was exited through
            % the OSD menu (or via error, or because intmax trials were
            % completed... though this is extraordinarily unlikely)
            
            % Close psychtoolbox and remove the daq from the engine
            self.cleanUp();
            
            % Store session end date
            self.sessionData.endDateTime       = now;
            self.sessionData.endTime           = GetSecs;
            self.sessionData.numberTotalTrials = trialNum;

            % Save final sessionData to "disk" and retrieve a copy as a
            % struct sd for returning.
            sd = self.saveSessionData();
            
        end

        function [target, latency] = waitTargetAcquired(self, duration, map)
           
            % Handle timing
            startTime = GetSecs;
            endTime   = startTime + duration/1000;
            
            % Default outputs
            latency   = NaN;
            target    = 0;
            
            % Run the loop
            while GetSecs < endTime
                
                % Get the window associated with the current eye position
                window = self.eye.getGazeWindow(map);
                
                % If the window is not the null window (0)...
                if window
                    latency = (GetSecs - startTime)*1000;
                    target  = window;
                    return
                end
                
            end
             
            % Pause briefly to keep loop running in a reasonable way
            WaitSecs(0.0001);
        end
            
            
        
%         function [err latency] = wait(self, duration, condition, interface, requirement)
%         
%             % Handle timing
%             startTime = GetSecs;
%             endTime   = startTime + duration/1000;
%             
%             % Default outputs
%             latency   = NaN;
%             err       = 0;
%             
%             % Handle the case where we're just waiting
%             if nargin < 3
%                 WaitSecs(endTime-GetSecs)
%                 return;
%             end         
%             
%             % If this is an 'until' call, reverse the logic
%             if strcmp('until', condition)
%                err         = 1;
%                requirement = ~requirement; 
%             end
%             
%             % Run the loop
%             while GetSecs < endTime
%                 if self.io.(interface) ~= requirement
%                     latency = (GetSecs - startTime)*1000;
%                     err     = ~err;
%                     return;
%                 end                 
%             end
%             
%             % Pause briefly to keep loop running in a reasonable way
%             WaitSecs(0.0001);
%             
%         end
        
        % Wait for conditions to be met
        function [err latency] = wait(self, duration, varargin)

            % Handle timing
            startTime = GetSecs;
            endTime   = startTime + duration/1000;
            latency   = NaN;
            
            % Holders for argument types
            argTypes  = {};
            whileArgs = {};
            untilArgs = {};
            
            % Store the property names and test values associated with
            % while and associated with until
            for arg = 1:3:numel(varargin)
                if strcmp('while', varargin{arg})
                    whileArgs = {whileArgs{:} {varargin{arg+1} varargin{arg+2}}};
                    argTypes  = {argTypes{:} 'while'};
                else
                    untilArgs = {untilArgs{:} {varargin{arg+1} varargin{arg+2}}};
                    argTypes  = {argTypes{:} 'until'};
                end
            end
            
            % Use the conditions to set default output values
            err       = ~isempty(untilArgs);
            
            % Now run the loop
            while GetSecs < endTime

                % First check 'while' arguments
                %failures = ~cellfun(@(x)self.daq.(x{1})==x{2}, whileArgs);
                failures = ~cellfun(@(x)self.io.(x{1})==x{2}, whileArgs);
                if any(failures)
                    latency = (GetSecs - startTime)*1000;
                    err     = failures;
                    return;
                end
                
                % Now check 'until' arguments
                if ~isempty(untilArgs)
                    %compliant = cellfun(@(x)self.daq.(x{1})==x{2}, untilArgs);
                    compliant = cellfun(@(x)self.io.(x{1})==x{2}, untilArgs);
                    if all(compliant)
                        latency = (GetSecs - startTime)*1000;
                        err     = false;
                        return;
                    else
                        err = ~compliant;
                    end
                end
                
                % Pause briefly to keep loop running in a reasonable way
                WaitSecs(0.0001);
            end
    
        end       
        
        % Converts degrees to pixels
        function px = deg2px(self, deg)
           px = round(tand(deg)*self.config.screenDistanceCm*self.pxPerCm);
        end
        
        % Makes a texture to be stored on the GPU for fast drawing
        function h = makeTexture(self, image)  
            h = Screen('MakeTexture', self.ptb.windowPtr, image);
            self.ptb.textures(h) = size(image);
        end
        
        % Lists all textures currently being stored
        function textures = getTextures(self)
            textures = self.ptb.textures.keys;
        end
                
        % Draws a stored texture on the screen, default to eye center
        function drawTexture(self, textureHandle, varargin)
            
            % Get the size of the texture
            if isempty(varargin)
                tSize = self.ptb.textures(textureHandle);
            else
                tSize = varargin{1};
            end
            
            % Create a rect to define the screen position
            destRect  = [self.displayCenter(1) - round(tSize(1)/2),   ...
                         self.displayCenter(2) - round(tSize(2)/2),   ...
                         self.displayCenter(1) + round(tSize(1)/2),   ...
                         self.displayCenter(2) + round(tSize(2)/2)];
            
            % Draw the texture
            Screen('DrawTexture', self.ptb.windowPtr, textureHandle, [], destRect);
        end

        % Draw a rectangle to the screen
        function drawRect(self, color, position)
            
            Screen('FillRect', self.ptb.windowPtr, color, position);
        
        end
        
        % Draws a circular fixation point at the eye center
        function drawFixation(self, diameter)
            
            % Create a rect to define the screen position
            destRect  = [self.displayCenter(1) - round(diameter/2),   ...
                         self.displayCenter(2) - round(diameter/2),   ...
                         self.displayCenter(1) + round(diameter/2),   ...
                         self.displayCenter(2) + round(diameter/2)];
            
            % Draw the circle on the screen
            Screen('FillOval', self.ptb.windowPtr, ...
                   self.config.fixationPointColor, ...
                   destRect, diameter);
            
        end
        
        function drawCue(self, location, diameter, color)
           
            if ~exist('color', 'var')
               color = self.config.cueColor; 
            end
            
            cueCenter = [self.displayCenter(1) + self.deg2px(location(1)), ...
                         self.displayCenter(2) + self.deg2px(location(2))];
            
            % Create a rect to define the screen position
            destRect  = [cueCenter(1) - round(diameter/2),   ...
                         cueCenter(2) - round(diameter/2),   ...
                         cueCenter(1) + round(diameter/2),   ...
                         cueCenter(2) + round(diameter/2)];
                     
%             Screen('FillOval', self.ptb.windowPtr,           ...
%                    self.config.cueColor,                     ...
%                    destRect, diameter);
%             
            Screen('FillOval', self.ptb.windowPtr,           ...
                   color, destRect, diameter);
            
                     
        end
        
        % Clear the screen
        function clearScreen(self)
            % Clear the task portion of the display by drawing a rectangle
            Screen('FillRect',                  ...
                   self.ptb.windowPtr,          ...
                   self.config.backgroundColor, ...
                   self.taskRect);
        end
        
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
            
        % Display the menu and wait for keypresses
        function quit = osdMenu(self)
           
            % By default, don't quit!
            quit     = 0;
            drawMenu = 1;
            
            % Clear keypresses
            FlushEvents('keyDown');
  
            % Loop forever in the menu until the user requests otherwise
            while true
     
                % Draw the menu if required
                if drawMenu
                    % Draw the menu on the OSD and flip.
                    self.updateOSD({'[r] to resume';            ...
                                    '[c] to calibrate';         ...
                                    '[v] to modify a variable'; ...
                                    '[q] to quit'});
                    self.flip(self.codes.displayUpdate);
                    drawMenu = 0;
                end
                                    
                % If a key has been pressed, handle it
                if CharAvail
                    switch GetChar(1)
                        case 'r'
                            break;
                        case 'c'
                            if ~isempty(self.eye)
                                self.eye.calibrate();
                                drawMenu = 1;
                            end
                            continue;
                        case 'v'
                            % wish I could hide task window
                            continue;
                        case 'q'
                            quit = 1;
                            return;
                    end
                end
            end
            
            % Update the OSD and flush keystrokes to resume the task
            FlushEvents('keyDown');
            self.updateOSD(self.currentTrial.osdText);
            self.flip(self.codes.displayUpdate);
                
        end
        
        % Flip the screen, returning a timestamp
        function [timestamp strobeTimes] = flip(self, codes)
            timestamp   = Screen('Flip', self.ptb.windowPtr, 0, 1);
            strobeTimes = self.strobeCodes(codes);
        end
        
        % Set and strobe a vector of codes through event lines
        function strobeTimes = strobeCodes(self, codes, varargin)
            
            % Create vector to hold times
            strobeTimes = nan(1, numel(codes));
            
            % Repeat the codes if requested
            if ~isempty(varargin)
                codes       = repmat(codes, 1, varargin{1});
            end
                
            % Iterate through codes, and strobe each, storing time
            for c = 1:numel(codes);
                strobeTimes(c)  = self.daq.strobeCode(codes(c));
                self.recordStrobe(codes(c), strobeTimes(c));
            end
        end
        
        % Deliver reward
        function goodMonkey(self, num, dur, pauseDur, code)
           
            % Store the strobe times
            %strobeTimes = nan(1,num);
            
            self.recordStrobe(code, self.daq.strobeCode(code));
            
            % Loop through the reward pulses (num)
            for r = 1:num
                %self.daq.reward = true;
                self.io.reward = true;
                WaitSecs(dur/1000);
                %self.daq.reward = false;
                self.io.reward = false;
                WaitSecs(pauseDur/1000);
                %strobeTimes(r) = self.daq.strobeCode(code);
            end
            
            self.recordStrobe(code, self.daq.strobeCode(code));
            
            % Record the strobe information
            %for c = 1:num
            %    self.recordStrobe(code, strobeTimes(c));
            %end
        end
        
        % Initialize Psychtoolbox
        function initializePsychtoolbox(self)
            
            % Extract information about screens
            self.display       = Screen('Resolution', self.config.screen);
            pxPerCmWidth       = self.display.width/self.config.screenWidthCm;
            pxPerCmHeight      = self.display.height/self.config.screenHeightCm;
            self.pxPerCm       = mean([pxPerCmWidth pxPerCmHeight]);
    
            % Assert that pixels are square, based on measurements
            assert(abs(pxPerCmWidth-pxPerCmHeight) < .1, ...
                   'Pixels not square. Measure monitor in cm')

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
        
        % Close down psychtoolbox and delete the daq from the engine
        function cleanUp(self)
 
            % Show the cursor again
            ShowCursor;
            
            % Set listen char, just to be sure
            ListenChar(1);
            
            % Close the screens
            Screen('Close');
            Screen('CloseAll');
            
            % Delete the daq from the engine
            self.daq.releaseDAQ();
            
        end
            
        % Initialize the sessionData struct
        function initializeSessionData(self)
            self.sessionData = struct(                                 ...
                'task',                self.config.experimentName,     ...
                'date',                datestr(date, 'yyyymmdd'),      ...
                'subjectName',         self.config.subjectName,        ...
                'fileName',            self.config.fileName,           ...
                'startDateTime',       [],                             ...
                'startTime',           [],                             ...
                'endDateTime',         [],                             ...
                'endTime',             [],                             ...
                'numberTotalTrials',   0,                              ...
                'numberCorrectTrials', 0,                              ...
                'trialStartTimes',     [],                             ...
                'trialErrors',         [],                             ...
                'reactionTimes',       [],                             ...
                'eventTimes',          {{}},                           ...
                'eventCodes',          {{}});
        end
        
        % Add fields with default values to sessionData
        function addSessionData(self, varargin)
            for arg = 1:2:numel(varargin)
               self.sessionData.(varargin{arg}) = varargin{arg+1};
            end
        end
        
        % Clear the current trial information holder
        function newTrial(self, trialNumber)
            
            defaultOSD = {
                
                ' ';
                'Hit [Esc] for menu...'
                };
            
            self.currentTrial = struct('trialNumber',  trialNumber,     ...
                                       'startTime',    [],            ...
                                       'trialError',   [],            ...
                                       'reactionTime', [],            ...
                                       'strobeCodes',  [],           ...
                                       'strobeTimes',  [],           ...
                                       'osdText',      {defaultOSD});
        end
        
        % Store information about a strobe in the current trial
        function recordStrobe(self, strobeCode, strobeTime)
            self.currentTrial.strobeCodes(end+1) = strobeCode;
            self.currentTrial.strobeTimes(end+1) = strobeTime; 
        end
       
        % Generate a unique filename for the session
        function generateUniqueFileName(self)

            % Generate a filename for the current session, ensuring
            % that no existing files are overwritten.
            nameNeeded = 1;
            nameNumber = 0;
    
            while nameNeeded
        
                putativeName = sprintf('%s-%s-%s-%02d.behavior',               ...
                    self.config.experimentName,                    ...
                    self.config.subjectName,                       ...
                    datestr(date, 'yyyymmdd'),              ...
                    nameNumber);
        
                % Now check the data directory, specified by dataPath, for any
                % existing files with the putative name
                nameNeeded = exist([self.config.dataPath putativeName], 'file') == 2;
                nameNumber = nameNumber+1;
                
            end
            
            self.config.fileName = putativeName;
            
        end
            
        % Add user-supplied config information, overriding defaults
        function userConfig(self, newConfig)
            
            % Get the field names from the user supplied config
            names = fieldnames(newConfig);
            
            % Iterate through the field names, and add to config
            for field = 1:numel(names)
                self.config.(names{field}) = newConfig.(names{field});
            end
            
        end
        
        % Add user-supplied config information, overriding defaults
        function userCodes(self, newCodes)
            
            % Get the field names from the user supplied config
            names = fieldnames(newCodes);
            
            % Iterate through the field names, and add to config
            for field = 1:numel(names)
                self.codes.(names{field}) = newCodes.(names{field});
            end
            
        end

        % Move information from currentTrial to sessionData
        function storeTrialData(self)
            % Convenient Data names
            curTrial = self.currentTrial;
            t        = curTrial.trialNumber;
            
            % Store data
            self.sessionData.numberTotalTrials   = t;
            self.sessionData.endTime             = GetSecs();
            self.sessionData.endDateTime         = now;
            self.sessionData.trialStartTimes(t)  = curTrial.startTime;
            self.sessionData.trialErrors(t)      = curTrial.trialError;
            self.sessionData.reactionTimes(t)    = curTrial.reactionTime;
            self.sessionData.eventTimes{t}       = curTrial.strobeTimes;
            self.sessionData.eventCodes{t}       = curTrial.strobeCodes;
            self.sessionData.numberCorrectTrials = ...
                nnz(self.sessionData.trialErrors == self.codes.correct);           
        end
        
        % Save sessionData to disk at dataPath
        function sd = saveSessionData(self)
            % Create a temporary copy of session data, to enable saving...
            sd = self.sessionData;
            save([self.config.dataPath self.config.fileName], 'sd');
        end
        
    end
    
end

