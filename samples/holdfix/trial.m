function trial(env, varargin)

    %handle some default outputs 
    env.currentTrial.reactionTime = NaN;
    
    % Present fixation point
    env.eye.drawEyeLinkFix;
    env.draw('clear');
    env.draw('fixation', env.config.fixSize);
    env.flip(1);
    
    reactionTime = 0;
    
    while reactionTime < 50
    
    % Wait for fixation 
    error = env.wait(env.config.fixWaitTime, 'until', 'fixation', true);
    
    % If there's an error, just end and go to the next trial
    if any(error) 
        env.currentTrial.trialError = 1;
        env.draw('clear');
        env.flip(1);
        return; 
    end
        
    % Otherwise the animal must hold fixation
    [error, reactionTime] = env.wait(env.config.fixHoldTime, 'while', 'fixation', true);
    
    end
    
    % If fixation is not maintained, wait for penalty time
    if any(error)
        env.currentTrial.trialError = 3;
        env.draw('clear');
        env.flip(1);
        env.wait(env.config.penaltyTime);
        return;
    end
    
    % At this point, the trial has been completed successfully, 
    % since errors always result in a return. Give reward and clear  
    env.draw('clear');
    env.flip(1);
    env.currentTrial.trialError = 0;
    env.goodMonkey(env.config.rewardNum, ...
                   env.config.rewardDur, ...
                   env.config.rewardPau, ...
                   1);
end