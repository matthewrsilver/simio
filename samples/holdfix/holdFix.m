function [sessionData, env] = holdFix

    % Add simio to the path
    addpath D:\toolboxes\simio
    
    % Prepare a simple configuration to run the task and use the DAQ
    conf.experimentName     = 'holdfix';     % experiment, no spaces, etc.   (string)
    conf.subjectName        = 'localMonkey'; % subject, no spaces, etc.      (string)
    conf.subjectEyeHeightCm = 71;            % height subject eye from box floor (cm)
    conf.itiDuration        = 4000;
    conf.fixSize            = .5;
    conf.fixationPointColor = [255 0 0];
    conf.fixationWindowSize = 5;
    conf.fixWaitTime        = 5000;
    conf.fixHoldTime        = 2000;
    conf.calibrationColor   = [255 255 255];
    conf.penaltyTime        = 5000;
    conf.rewardNum          = 6;
    conf.rewardDur          = 20;
    conf.rewardPau          = 60;
    conf.screen             = 0;             % screen for psychtoolbox window
    conf.screenDistanceCm   = 46;            % distance between eye and screen   (cm)
    conf.screenWidthCm      = 37.4;          % width of display                  (cm)
    conf.screenHeightCm     = 30;            % height of display                 (cm)
    conf.screenElevationCm  = 61;            % display bottom distance off floor (cm)
    conf.eyeElevationCm     = 73;            % eye distance off floor            (cm)
    conf.useEyeLink         = 1;
    conf.daqReward          = [0 1];
    conf.daqStrobe          = [1 1];         % strobe                     [line port]
    conf.daqCodes           = [2 1; 3 1; ... % code lines                 [line port]
                               4 1; 5 1; ...
                               6 1; 7 1; ...
                               0 2; 1 2; ...
                               2 2; 3 2; ...
                               4 2; 5 2; ...
                               6 2; 7 2];
    
    
    %% Prepare the task environment
    %
    % Declare and initialize a simio environment, which provides access to
    % a number of useful tools for presenting stimuli on the screen,
    % detecting responses, and timestamping events
  
    env = Simio('config', conf);
    
    % Use task environment to get pixel sizes from degree sizes
    env.config.fixSize = env.deg2px(conf.fixSize);
    
    
    %% Run the session
    %
    % Call the function runSession in the simio environment, passing
    % function handles that deal with the trial as well as pre- and post-
    % trial routines.  Additional values can be passed after these function
    % handles, and those values will be available when the functions below
    % are evaluated.  In this case, we'll pass a struct 'stimuli' that has
    % named fields containing texture handles.
 
    sessionData = env.runSession(@(x)x, @trial, @(x)x);

end