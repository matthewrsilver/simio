function codes = dmscategory_codes(varargin)

% Trial outcome codes
codes.correct       = 0;
codes.noResponse    = 1;
codes.fixationBreak = 3;
codes.earlyResponse = 5;
codes.wrongResponse = 6;
codes.leverBreak    = 7;
codes.ignored       = 8;
codes.unknown       = 9;
    
% Event codes    
codes.beginTrial    = 10;
codes.endTrial      = 11;
codes.fixAcquire    = 12;
codes.fixBreak      = 13;
codes.leverDown     = 14;
codes.leverRelease  = 15;
codes.beginITI      = 16;
codes.endITI        = 17;
codes.fixOn         = 18;
codes.fixOff        = 19;
codes.sampleOn      = 20;
codes.sampleOff     = 21;
codes.testOn        = 22;
codes.testOff       = 23;
codes.test2On       = 24;
codes.test2Off      = 25;
codes.reward        = 26;
codes.displayUpdate = 27;
codes.screenClear   = 28;
codes.penaltyBegin  = 29;
    
% Trial types    
codes.matchTrial    = 30;
codes.nonmatchTrial = 31;

end