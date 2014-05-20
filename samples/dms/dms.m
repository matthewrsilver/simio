function [sessionData, env] = dms
%DMSCATEGORY Run the dmscategory experiment with simio/Psychtoolbox.
%
%   The dmscategory task is a version of the delayed match to sample (DMS)
%   paradigm. During each trial of the DMS task, subjects are presented a 
%   sample stimulus and, following a brief delay, a test stimulus.
%   Subjects must indicate whether the test stimulus matches the sample
%   stimulus, according to learned or specified match criteria. Often,
%   subjects will respond when the stimuli match, and withhold the response
%   when presented with a nonmatching test stimulus. If the subject
%   correctly withholds the response on nonmatch trials, a matching
%   stimulus is presented after a second delay interval. Response to this
%   matching stimulus is then required for correct performance.
%
%   In the dmscategory task, stimuli are considered to match when they are
%   drawn from the same category of dot stimuli, as described by Posner in
%   1967 when introducing the "prototype distortion" task.

    
     %% Prepare the task environment
    %
    % Declare and initialize a simio environment, which provides access to
    % a number of useful tools for presenting stimuli on the screen,
    % detecting responses, and timestamping events
    
    % Construct simio environment
    env = Simio('config', dms_config, 'codes',  dms_codes);
    
    % Convert stimulus sizes to degrees
    env.config.fixationPointSizePx = env.deg2px(env.config.fixationPointSize);
    env.config.stimulusSizePx      = env.deg2px(env.config.stimulusSize);
            
    % Add fields for stimulus numbers, matchTrials, etc. in the sessionData
    % struct, so they can be stored and used during the session.
    env.addSessionData('sampleStimulus',  [],                           ...
                       'sampleCategory',  [],                           ...
                       'testStimulus',    [],                           ...
                       'testCategory',    [],                           ...
                       'matchTrials',     [],                           ...
                       'nonmatchTrials',  [],                           ...
                       'matchFrequency',  []);
 
                   
    % Provide functions handles, dealing with the three task phases:
    % pre-trial, post-trial, and the trial itself.
    env.setTaskFunctions('preTrial',  @dmsPreTrial,                     ...
                         'trial',     @dmsTrial,                        ...
                         'postTrial', @dmsPostTrial);
                   
                   
    %% Initialize Stimulus Data
    %
    % Using cateogry and stimulus information from the configuration files,
    % prepare stimuli for drawing on the screen.
    
    % What kind of data will I pass to the trial functions?
    
    % Colors?
    % Textures?
    % Arguments to env.draw?? <--- interesting, let's try it...
    
    % Cell array for each category 
    stimuli{1} = {};
    stimuli{2} = {};
    
    
        
    %% Run the session
    %
    % Call the function runSession in the simio environment, passing
    % function handles that deal with the trial as well as pre- and post-
    % trial routines. Pass textures and other variables along as well.
    
    sessionData = env.runSession(stimuli);
   
        
        
        
    
    

end
