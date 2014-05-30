function [sessionData, env] = changeDetect
    
    %% Prepare the default task environment
    %
    % Declare and initialize the Simio environment, which provides access to
    % a number of useful tools for presenting stimuli on the screen,
    % detecting responses, and timestamping events
  
    env = Simio();
    
    
    %% Add a task function
    %
    % Provide a function handle that will be used to play out each
    % individual trial as the session runs.
    
    env.setTaskFunctions('trial', @changeDetectTrial);
    
    
    %% Add a keyboard interface
    %
    % An important initial stage is the addition of interfaces that will be 
    % in the task functions to allow the subject to interact with the task.
    
    env.io.addInterface('keypress', 'in', @env.io.keypress);
    
    
    %% Run the session
    %
    % Call the function runSession to begin the task execution loop, passing 
    % data to be used by the task functions (in this case, the set of letters
    % that may be presented on the screen), and store the output in a struct 
    % called sessionData
 
    sessionData = env.runSession();

end