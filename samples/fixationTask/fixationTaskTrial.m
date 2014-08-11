function fixationTaskTrial(env, varargin)

    % Handle some default outputs 
    env.currentTrial.reactionTime = NaN;
    env.currentTrial.trialError   = NaN;
    
    % Grab the fixation location information
    fixationCoords = varargin{1};
    
    % Choose a fixation location for the current trial
    fixLocIndex  = randi(numel(fixationCoords));
    fixLocation  = fixationCoords{fixLocIndex};
    fixInterface = sprintf('fixation%d', fixLocIndex);
    
    % Present a fixation point at the desired location
    env.draw('clear');
    env.draw('cue', fixLocation, env.config.fixationSizePx);
    env.flip(1);
        
    % Wait for the animal to acquire fixation
    [error, reactionTime] = env.wait(env.config.initDuration, 'until', fixInterface, true);
    
    % If the subject didn't acquire fixation, then there's an error
    if error
        env.draw('clear');
        env.flip(1);
        env.wait(2000);
        env.currentTrial.trialError = 1;
        return;
    end
        
    fixTime = env.config.fixDuration + randi(env.config.fixDurationJitter);
    
    % If there was no error, then wait while the animal maintains fixation
    error = env.wait(fixTime, 'while', fixInterface, true);
    
    % If there's an error, the subject broke fixation
    if error
        env.draw('clear');
        env.flip(1);
        env.wait(env.config.penaltyTime);
        env.currentTrial.trialError = 3;
        return;
    end
    
    % At this point, the trial has been completed successfully, 
    % since errors always result in a return.
    
    % Give reward
    env.goodMonkey(env.config.rewardPulseNumber,   ...
                   env.config.rewardPulseDuration, ...
                   env.config.rewardPauseDuration, ...
                   1);
    
    env.currentTrial.reactionTime = reactionTime;
    env.currentTrial.trialError   = 0;

end