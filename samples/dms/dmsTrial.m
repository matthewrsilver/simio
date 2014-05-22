function dmsTrial(env, varargin) %#ok<*FNDSB>

  % Extract some info from env for convenience
  codes      = env.codes;
  task       = env.config;
  stimuli    = varargin{1};
  sampleArgs = stimuli{env.currentTrial.sampleInd};
  testArgs   = stimuli{env.currentTrial.testInd};
  test2Args  = stimuli{env.currentTrial.test2Ind};
  
  % Set default outputs
  env.currentTrial.trialError   = codes.unknown;
  env.currentTrial.reactionTime = NaN;
  env.currentTrial.startTime    = GetSecs;
      
  % Strobe the trial type
  if env.currentTrial.matchTrial, 
      env.strobeCodes(codes.matchTrial);
  else
      env.strobeCodes(codes.nonmatchTrial);
  end
  
  
  
  %% Present fixation point, and wait for fixation
  %  =====================================================================
  
  env.draw('clear');
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.fixOn);
  
  % Begin process of detecting fixation acquisition
  % with a grace period for accidental window entry.
  successfulFixation = false;
  beginTime          = GetSecs;
  
  % While there's still time left
  while (GetSecs - beginTime) < task.initDuration
      
      % Compute the time left for acquisition
      remainingTime = task.initDuration - (GetSecs - beginTime);
      
      % Wait for fixation
      error = env.wait(remainingTime,                                  ...
          'until', 'fixation', true,                                   ...
          'until', 'lever',    true);
      
      % If fixation was never acquired, this is an error
      if any(error); 
          handleError(codes.ignored); 
          return;
      end
      
      % If fixation was acquired, wait before stimulus presentation
      [error, timeInWindow] = env.wait(task.initFixDuration,           ...
          'while', 'fixation', true,                                   ...
          'while', 'lever',    true);
      
      % If fixation was broken, we either have to deal with it 
      % as an error, or await reinitiation
      if any(error)
          
          % If the time in the window was too great, this is an error
          if timeInWindow > task.fixGracePeriod 
              currentCodes = [codes.fixationBreak codes.leverBreak];
              handleError(currentCodes(find(error)), timeInWindow);  
              return; 
          end
          
          % A fixation break within the grace period will result in
          % another iteration through the loop
          continue;
          
      % If fixation was not broken, then we can move on with the trial
      else successfulFixation = true; break;
      end
      
  end
  
  % If we've moved on from the loop, this can mean that we broke because of
  % a success, or that the time constraint on the loop simply expired. We
  % need to detect the latter occasion and mark this as an error.
  if ~successfulFixation; handleError(codes.ignored); return; end
    
  
  
  %% Present sample stimulus
  %  =====================================================================
  
  env.draw('clear');
  env.draw(sampleArgs{:}); 
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.sampleOn);
  
  % Ensure fixation and lever are maintained
  [error, reactionTime] = env.wait(task.sampleDuration,                ...
      'while', 'fixation', true,                                       ...
      'while', 'lever',    true);
    
  if any(error); 
      currentCodes = [codes.fixationBreak, codes.leverBreak];
      handleError(currentCodes(find(error)), reactionTime);
      return;
  end
  
 
  
  %% Show fixation point for delay
  %  =====================================================================
  env.draw('clear');
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.sampleOff);
  
  % Ensure fixation and lever are maintained
  error = env.wait(task.delayDuration,                                 ...
      'while', 'fixation', true,                                       ...
      'while', 'lever',    true);
  
  if any(error);
      currentCodes = [codes.fixationBreak codes.leverBreak];
      handleError(currentCodes(find(error)));
      return;
  end
  
  
  
  %% Present test stimulus
  %  =====================================================================
  env.draw('clear');
  env.draw(testArgs{:});
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.testOn);
  
  %
  %
  % From here, the task logic diverges on the basis of trial type. On
  % match trials, we await the release of the lever. On nonmatch
  % trials, we require continued fixation and lever holding.
  %
  %

  
  % If the current trial is a match trial:
  if env.currentTrial.matchTrial

      % Wait until the lever is released
      [error, reactionTime] = env.wait(task.testDuration,              ...
          'while', 'fixation', true,                                   ...
          'until', 'lever',    false);
          
      % If there were any errors, handle the error
      if any(error) 
          currentCodes = [codes.fixationBreak, codes.wrongResponse];
          handleError(currentCodes(find(error)), reactionTime);
          return;
      end
      
      % Otherwise, the trial has been completed successfully
      handleSuccess(reactionTime);
      return;
  end
  
  
  %
  %
  % The logic for match trials has now been completed. All subsequent
  % code applies only to nonmatch trials, as both errors and correct
  % responses trigger a return above.
  %
  %
  
  
  
  %% On nonmatch: ensure fixation and lever are maintained
  %  =====================================================================
  
  [error, reactionTime] = env.wait(task.testDuration,                  ...
      'while', 'fixation', true,                                       ...
      'while', 'lever',    true);
       
  if any(error) 
      currentCodes = [codes.fixationBreak codes.wrongResponse];
      handleError(currentCodes(find(error)), reactionTime);
      return;
  end
  
  
  
  %% Show fixation point for the second delay
  %  =====================================================================
  
  env.draw('clear');
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.testOff);
      
  % Ensure fixation and lever are maintained
  error = env.wait(task.secondDelayDuration,                           ...
      'while', 'fixation', true,                                       ...
      'while', 'lever',    true);
      
  if any(error)
      currentCodes = [codes.fixationBreak codes.earlyResponse];
      handleError(currentCodes(find(error)));
      return;
  end
    
  
  
  %% Present the second test stimulus
  %  =====================================================================
  env.draw('clear');
  env.draw(test2Args{:});
  env.draw('fixation', task.fixationPointSizePx);
  env.flip(codes.test2On);
      
  % Wait until the lever is released
  [error, reactionTime] = env.wait(task.secondTestDuration,            ...
      'while', 'fixation', true,                                       ...
      'until', 'lever',    false);
      
  if any(error); 
      currentCodes = [codes.fixationBreak codes.noResponse];
      handleError(currentCodes(find(error)));
      return;
  end
  
  
  
  %% Trial Completed
  %  =====================================================================
  
  % At this point, the trial has been completed without error. Match trial
  % outcomes have already been handled above. Return is not necessary but
  % helps readability...
  handleSuccess(reactionTime);
  return;
  
  
  
  
  %
  %
  % The trial has been completed here, and the outcome handled. Below are
  % functions that are used to handle the trial outcomes
  %
  %
  
  
  
  
  
  
  
  
  
  
  %% Handlers for trial outcomes
  %  =====================================================================
  
  % Called on successful completion of the trial
  function handleSuccess(rt)
      
      % Set trial information 
      env.currentTrial.trialError   = codes.correct;
      env.currentTrial.reactionTime = rt;

      % Give reward
      env.goodMonkey(task.rewardPulseNumber,   ...
                     task.rewardPulseDuration, ...
                     task.rewardPauseDuration, ...
                     codes.reward);
  
      % Clear screen? Strictly unnecessary...
      env.draw('clear');
      env.flip(codes.screenClear);
        
  end
  
  % Called when an error is made, before ending the trial
  function handleError(errorCode, rt)
      
      % Set default value for optional parameter rt
      if ~exist('rt', 'var'); rt = NaN; end;
      
      % Store information about trial outcome
      env.currentTrial.reactionTime = rt;      
      env.currentTrial.trialError   = errorCode;
            
      % Flash the screen on certain error types?
      if ismember(errorCode, [codes.leverBreak codes.fixationBreak])
          Screen('FillRect', env.ptb.windowPtr, [255 0 0], env.taskRect);
          env.flip(1);
          env.wait(25);
      end
        
      % Prepare screen and begin penalty time
      env.draw('clear');
      env.flip(codes.screenClear);
      env.strobeCodes(codes.penaltyBegin);
      env.eyeLinkDraw('clear');
      env.wait(task.penaltyTime);
      
  end    
  
  
end
