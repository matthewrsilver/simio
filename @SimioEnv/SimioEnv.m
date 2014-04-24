classdef SimioEnv < handle
%SIMIOENV Environment for monkey training
%   SimioEnv has three essential functions. To detect external
%   events such as lever presses and eye movements though a DAQ 
%   and through ethernet, to display stimuli on the screen using 
%   Psychtoolbox, and to mark important times with event codes 
%   through the DAQ.
    
    properties
        
        % SimioIO object, with hooks to IO interfaces in DAQ and EyeLink
        io

        % SimioDAQ object
        daq
        
        % SimioEyeLink object
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
        config
        codes
        
    end
    
    methods
        
        % Constructor for the SimioEnv class
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
            
        
        % Flip the screen, returning a timestamp
        function [timestamp strobeTimes] = flip(self, codes)

            % Strobe codes before flip, to ensure accurate
            % post-flip timing (ie. reaction times)
            strobeTimes = self.strobeCodes(codes);
            timestamp   = Screen('Flip', self.ptb.windowPtr, 0, 1);
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

