function [sessionData, env] = fixationTask
    
    %% Prepare the default task environment
    %
    % Declare and initialize the Simio environment, which provides access to
    % a number of useful tools for presenting stimuli on the screen,
    % detecting responses, and timestamping events
  
    env = Simio('config', fixationTask_config);
    
    env.config.fixationSizePx = env.deg2px(env.config.fixationPointSize);
    
    %% Add a task function
    %
    % Provide a function handle that will be used to play out each
    % individual trial as the session runs.
    
    env.setTaskFunctions('trial', @fixationTaskTrial);
    

    %% Specify fixation window centers, and add an interface for each
    %
    %  Begin by specifying a cell array that contains a set of coordinates
    %  that serve as fixation locations. Then iterate through and add I/O
    %  interfaces to the Simio environment using the function gazeAt.
   
    % Coordinates of fixation cues, in degrees
    ecc    = env.config.cueEccentricity;
    window = env.config.fixationWindowSize;
    fixationCoords = {[-ecc -ecc], [0 -ecc], [ecc -ecc], ...
                      [-ecc    0], [0    0], [ecc    0], ...
                      [-ecc  ecc], [0  ecc], [ecc  ecc]};
    
    % Iterate through and add each coordinate as an interface
    for i = 1:numel(fixationCoords)
        
        % Add the interface
        env.io.addInterface(sprintf('fixation%d', i), 'in',            ...
                            @(x)env.gazeAt(fixationCoords{i}, window));
        
    end
                  
    
    
    
    %% Run the session
    %
    % Call the function runSession to begin the task execution loop, passing 
    % data to be used by the task functions (in this case, the set of letters
    % that may be presented on the screen), and store the output in a struct 
    % called sessionData
 
    sessionData = env.runSession(fixationCoords);

end