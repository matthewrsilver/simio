function dmsPostTrial(env, varargin)

    % Unpack to make things a bit cleaner
    curTrial = env.currentTrial;
    t        = curTrial.trialNumber;

    % Store information in sessionData
    env.sessionData.numberTotalTrials   = t;
    env.sessionData.endTime             = GetSecs();
    env.sessionData.endDateTime         = now;
    env.sessionData.trialStartTimes(t)  = curTrial.startTime;
    env.sessionData.sampleInd(t)        = curTrial.sampleInd;
    env.sessionData.testInd(t)          = curTrial.testInd;    
    env.sessionData.trialErrors(t)      = curTrial.trialError;
    env.sessionData.reactionTimes(t)    = curTrial.reactionTime;
    env.sessionData.matchTrials(t)      = curTrial.matchTrial;
    env.sessionData.nonmatchTrials(t)   = ~curTrial.matchTrial;
    env.sessionData.eventTimes{t}       = curTrial.strobeTimes;
    env.sessionData.eventCodes{t}       = curTrial.strobeCodes;
    env.sessionData.numberCorrectTrials = ...
        nnz(env.sessionData.trialErrors == env.codes.correct);

end