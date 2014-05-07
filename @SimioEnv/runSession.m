% Begin a trial loop, executing function handles pre, during, post
function sd = runSession(self, preTrial, trial, postTrial, varargin)

    % %%%%%%%%%%%%%% PREPARE TO BEGIN THE SESSION %%%%%%%%%%%%%% %

    % Start with initialization of Psychtoolbox window
    self.initWindow();
        
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
        self.draw('clear');
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
