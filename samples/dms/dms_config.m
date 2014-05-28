function config = dms_config

% basic information
config.experimentName        = 'dms';         % experiment, no spaces, etc.   (string)
config.subjectName           = 'pollo';       % subject, no spaces, etc.      (string)
config.subjectEyeHeightCm    = 71;            % height subject eye from box floor (cm)

% Task appearance parameters
config.backgroundColor       = [60 60 60];    % background color during task (0 - 255)
config.fixationPointColor    = [255 0 0];     % color of fixation point      (0 - 255)
config.fixationPointSize     = 0.5;           % diameter of fixation point       (deg)
config.fixationWindowSize    = 7;             % diameter of fixation window      (deg)
config.stimulusSize          = 4;             % width & height of stimuli        (deg)

% Task timing parameters	          
config.initDuration          = 3000;          % time to wait for lever press      (ms)
config.initFixDuration       = 300;           % duration of initial fixation      (ms)
config.fixGracePeriod        = 50;            % time before fixation initiated    (ms)
config.sampleDuration        = 500;           % duration of sample presentation   (ms)
config.delayDuration         = 500;           % duration of memory delay          (ms)
config.testDuration          = 700;           % duration of test presentation     (ms)
config.secondDelayDuration   = 200;           % duration of second delay          (ms)
config.secondTestDuration    = 700;           % duration of second test           (ms) 
config.itiDuration           = 4000;          % duration of inter-trial interval  (ms)
				          
% Error and reward timing	          
config.penaltyTime           = 6000;          % duration of penalty time          (ms)
config.rewardPulseDuration   = 20;            % duration of reward pulses         (ms)
config.rewardPauseDuration   = 60;            % duration of pauses between pulses (ms)
config.rewardPulseNumber     = 7;             % number of reward pulses            (#)
				       
% Eyelink parameters
config.useEyeLink            = 1;
config.calibrationColor      = [255 0 0];

% Physical properties of subject display
config.screen                = 0;             % screen for psychtoolbox window
config.screenDistanceCm      = 46;            % distance between eye and screen   (cm)
config.screenWidthCm         = 37.4;          % width of display                  (cm)
config.screenHeightCm        = 30;            % height of display                 (cm)
config.screenElevationCm     = 61;            % display bottom distance off floor (cm)
config.eyeElevationCm        = 73;            % eye distance off floor            (cm)
config.osdHeight             = 200;           % height of on screen display       (px)

% DAQ information
config.daqAdaptor            = 'nidaq';       % name of daq adaptor on pc
config.daqID                 = 'Dev1';        % daq ID on pc       
config.daqLever              = [0 0];         % lever                      [line port]
config.daqReward             = [0 1];         % reward                     [line port]
config.daqStrobe             = [1 1];         % strobe                     [line port]
config.daqCodes              = [2 1; 3 1; ... % code lines                 [line port]
                             4 1; 5 1; ...
                             6 1; 7 1; ...
                             0 2; 1 2; ...
                             2 2; 3 2; ...
                             4 2; 5 2; ...
                             6 2; 7 2];

% Paths to data and stimuli
%config.simioPath             = 'D:\toolboxes\simio';
%config.dataPath              = 'D:\data\';
%config.archiveLocalPath      = 'D:\data\archive\';
%config.archiveRemotePath     = 'M:\dmscategory\data\archive\';

end