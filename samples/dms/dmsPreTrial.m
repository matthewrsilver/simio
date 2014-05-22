function dmsPreTrial(env, varargin)

    % Extract important information
    stimuli         = varargin{1};
    numStimuli      = numel(stimuli);
    
    if env.sessionData.numberTotalTrials > 1
        matchTrials     = env.sessionData.matchTrials;
        nonmatchTrials  = env.sessionData.nonmatchTrials;
        trialErrors     = env.sessionData.trialErrors;
        correctTrials   = trialErrors == env.codes.correct;
    
        % Begin with a brief analysis of the session thus far. The results of
        % this analysis can inform the likelihood of choosing match or nonmatch
        % in the forthcoming trial.
    
        % First find the trials the animals attempted
        leverDownTrials = findLeverDownTrials(trialErrors);
        attemptedTrials = ~(  leverDownTrials                               ...
                            | trialErrors == env.codes.ignored              ...
                            | trialErrors == env.codes.noResponse);
    
        % Percent correct for all trials, match, and nonmatch
        totalPct    = nnz(correctTrials)/nnz(attemptedTrials)*100;
        matchPct    = nnz(matchTrials(correctTrials))/nnz(matchTrials(attemptedTrials))*100;
        nonmatchPct = nnz(nonmatchTrials(correctTrials))/nnz(nonmatchTrials(attemptedTrials))*100;
    else
        correctTrials = 0; totalPct = 0; matchPct = 0; nonmatchPct = 0;
    end
    
    % Generate a random number between 0 and 1 and then give that
    % value a 1, by putting it in the first bin with histc, if it
    % falls in between 0 and matchFrequency. If the random number
    % falls outside of 0 and matchFrequency, histc returns 0.
    [~, matchTrial] = histc(rand, [0 .5]);

    % Choose sample, match and nonmatch stimuli
    sampleInd   = randi(numStimuli);
    matchInd    = sampleInd;         
    nonmatchInd = randsample(setdiff(1:numStimuli, sampleInd), 1);
    
    % Convert the above match/nonmatch stimulus information into 
    % test1/test2 information, based on the match/nonmatch status 
    % of the trial 
    if matchTrial
        testInd  = matchInd;
        test2Ind = nonmatchInd;
    else
        testInd  = nonmatchInd;
        test2Ind = matchInd;
    end
        
    % Store the data just generated about the current trial
    env.currentTrial.matchTrial  = matchTrial;
    env.currentTrial.sampleInd   = sampleInd;
    env.currentTrial.testInd     = testInd;
    env.currentTrial.test2Ind    = test2Ind;
        
    % Set the text for the OSD
    if ~isnan(env.currentTrial.matchTrial)
        if env.currentTrial.matchTrial 
            matchString = 'match'; 
        else
            matchString = 'nonmatch'; 
        end
    end
    
    sessionDuration = now - env.sessionData.startDateTime;
    startStr        = datestr(env.sessionData.startDateTime, 'HH:MM');
    durationStr     = [datestr(sessionDuration, 'HH') ' hours, ' datestr(sessionDuration, 'MM') ' minutes'];
    
    env.currentTrial.osdText = {                                                                                  ...
        [env.config.fileName]; ' ';                                                                               ...
        sprintf('Start Time:       %s (%s)', startStr, durationStr);                                               ...
        sprintf('Trial Type:       %s', matchString);                                                              ...
        sprintf('Trials Finished:  %d (%d correct)',env.currentTrial.trialNumber-1, nnz(correctTrials));           ...
        sprintf('Performance:      %.0f%% total; %.0f%% match; %.0f%% nonmatch', totalPct, matchPct, nonmatchPct); ...
        ' '; 'Hit [Esc] for menu...'};
end