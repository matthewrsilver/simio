function changeDetectTrial(env, varargin)
    
    % Handle some default outputs 
    env.currentTrial.reactionTime = NaN;
    env.currentTrial.trialError   = NaN;
    
    % Useful stimulus information
    stimPosition = repmat(env.displayCenter, 1, 2) + [-100 -100 100 100];
    
    % Present a rectangle at the center of the screen
    env.draw('clear');
    env.draw('rect', [255 0 0], stimPosition);
    env.flip(1);
        
    % Wait for some variable amount of time, during which keypresses are
    % not allowed and result in an error.
    error = env.wait(1000 + randi(1000), 'while', 'keypress', false);
    
    % If the subject pressed a key before the change, it's an error. Mark
    % the error and wait through a time-out penalty.
    if error
        env.draw('clear');
        env.flip(1);
        env.wait(2000);
        env.currentTrial.trialError = 1;
        return;
    end
        
    % Change the color of the rectangle
    env.draw('clear');
    env.draw('rect', [0 255 0], stimPosition);
    env.flip(1);
    
    % Wait for the subject to press a key
    [error, reactionTime] = env.wait(2000, 'until', 'keypress', true);
    
    % If the subject did not press a key, mark the error and wait.
    if error
        env.draw('clear');
        env.flip(1);
        env.wait(2000);
        env.currentTrial.trialError = 1;
        return;
    end
    
    % At this point, the trial has been completed successfully, 
    % since errors always result in a return.
    env.currentTrial.reactionTime = reactionTime;
    env.currentTrial.trialError   = 0;

end