classdef SimioEnv < handle & SimioPsychtoolbox & SimioEyeLink
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
        
        % Structs to store session and trial information
        sessionData
        currentTrial
        config
        codes

        % Handles for task functions supplied by user. Initial
        % handles simply return an empty value.
        preTrialHandle  = @(x)[];
        trialHandle     = @(x)[];
        postTrialHandle = @(x)[];
        
    end
    
    methods
        
        % Constructor for the SimioEnv class
        function self = SimioEnv(varargin)
           
            % First thing: shuffle the random number generator
            try
                rng('shuffle');
            catch err %#ok<NASGU>
                % Roll back to earlier, ugly syntax. Should be the
                % same (grabbed mostly from rng code) but not 
                % certain, so display message...
                disp('WARNING: Using old random number generation')
                s = RandStream('mt19937ar', 'Seed', sum(100*clock));
                RandStream.setDefaultStream(s); %#ok<SETRS>
            end
            
            % Extract configuration and codes information
            for arg = 1:2:numel(varargin)
                switch varargin{arg}
                    case 'config'
                        tmpConfig = varargin{arg+1};
                    case 'codes'
                        tmpCodes = varargin{arg+1};
                    otherwise
                        disp([varargin{arg} ' is not a valid parameter']);
                end
            end

            % Inherit SimioPsychtoolbox and SimioEyeLink...
            self@SimioPsychtoolbox(tmpConfig);
            self@SimioEyeLink(tmpConfig);
            
            % Store config and codes as properties; must be done
            % after construction of inherited classes, hence the
            % passage of the config struct to each constructor.
            self.config = tmpConfig;
            self.codes  = tmpCodes;
            
            % Using the configuration information, generate a file name
            self.generateUniqueFileName();
            
            % Initialize the sessionData structure
            self.initializeSessionData();
            
            % Initialize the currentTrial structure 
            self.newTrial(0);
            
            % Initialize simioIO object
            disp('Initializing Simio IO Interface...');
            self.io  = SimioIO(self);

            
            % This is a funny spot for initialization of the fixation
            % interface, though it does make sense that it needs to be
            % after SimioIO... Anyway:
            %
            % Now that we've got things configured in the EyeLink,
            % but before beginning calibration, etc, add a hook in
            % the main simio IO for fixation
            try self.io.addInterface('fixation', 'in', @(x)self.fixation);
            catch err, disp(err.message);
            end

            % Initialize simioDAQ object
            disp('Initializing Simio DAQ...');
            self.daq = SimioDAQ(self);
                
        end
        
        % Desctructor for the simio class
        function delete(self) %#ok<INUSD>

            % Delete the daq, shutting down the engine.
            %delete(self.daq);

            % Reenable the keyboard
            ListenChar(1);
                        
            % Close the psychtoolbox screens
            Screen('CloseAll');
            
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

