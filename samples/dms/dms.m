function [sessionData, env] = dms
%DMS Run the dms experiment with Simio/Psychtoolbox.
%
%   The delayed match to sample (DMS) task is a useful paradigm for 
%   measuring neural activity related to working memory. During each 
%   trial of the DMS task, subjects are presented a sample stimulus and, 
%   following a brief delay, a test stimulus. Subjects must indicate 
%   whether the test stimulus matches the sample stimulus, according to 
%   learned or specified match criteria -- here when the stimulus is the
%   same. In this variant, subjects respond by releasing a lever when the 
%   stimuli match, and withhold the response when presented with a 
%   nonmatching test stimulus. If the subject correctly withholds the 
%   response on nonmatch trials, a matching stimulus is presented after 
%   a second delay interval. Response to this matching stimulus is then
%   required for correct performance.

    
     %% Prepare the task environment
    %
    % Declare and initialize a simio environment, which provides access to
    % a number of useful tools for presenting stimuli on the screen,
    % detecting responses, and timestamping events
    
    % Construct simio environment
    env = Simio('config', dms_config, 'codes',  dms_codes);
                      
    % Provide functions handles, dealing with the three task phases:
    % pre-trial, post-trial, and the trial itself.
    env.setTaskFunctions('preTrial',  @dmsPreTrial,                     ...
                         'trial',     @dmsTrial,                        ...
                         'postTrial', @dmsPostTrial);
                   
                   
    %% Initialize Stimulus Data
    %
    % Using cateogry and stimulus information from the configuration files,
    % prepare stimuli for drawing on the screen. Here, we'll define each
    % stimulus as a cell array containing the arguments that should be
    % passed to the draw command. Because all stimuli are presented at the
    % center, this is a particularly compact and convenient way to deal
    % with things, but it limited to this case.
    
    % Convert stimulus sizes to degrees
    env.config.fixationPointSizePx = env.deg2px(env.config.fixationPointSize);
    env.config.stimulusSizePx      = env.deg2px(env.config.stimulusSize);
    
    % Make textures to allow for rapid stimulus drawing
    texture01 = env.makeTexture(imread('stim01.bmp'));
    texture02 = env.makeTexture(imread('stim02.bmp'));
    
    % Build a stimulus rect at the center of the screen
    halfStim = round(env.config.stimulusSizePx/2);
    stimRect = [env.displayCenter(1) - halfStim; 
                env.displayCenter(2) - halfStim;
                env.displayCenter(1) + halfStim; 
                env.displayCenter(2) + halfStim]; 
    
    %           |  type  |  RGB color  | position |
    stimuli  = {{ 'rect',    [255 100   0], stimRect }
                { 'rect',    [0   100 255], stimRect }
                { 'texture', texture01,     stimRect }
                { 'texture', texture02,     stimRect }};
    
    
        
    %% Run the session
    %
    % Call the function runSession in the simio environment, passing
    % function handles that deal with the trial as well as pre- and post-
    % trial routines. Pass textures and other variables along as well.
    
    sessionData = env.runSession(stimuli);
   
end
