function [err, latency] = wait(self, duration, varargin)
% Wait for conditions to be met

    % Handle timing
    startTime = GetSecs;
    endTime   = startTime + duration/1000;
    
    % Default outputs
    latency   = NaN;
    numTests  = ceil((nargin-2)/3);
    err       = zeros(1, max(numTests, 1));
    
    % Handle the case where we're just waiting, and otherwise set
    % the default output, using the number of tests specified
    if numTests < 1
        WaitSecs(endTime-GetSecs);
        return;
    end
       
    % Determine which tests use 'until' logic
    untils = strcmp(varargin(1:3:nargin-2), 'until');
    
    % Run the loop
    while GetSecs < endTime
        
        % Iterate through tests on each loop run
        for test = 1:numTests
        
            % Base argument for current test
            ifaceArg = (test-1)*3+2;
            
            % Check the current test
            same = self.io.(varargin{ifaceArg}) == varargin{ifaceArg+1};
            
            % If 'until' and same, then this is a success
            if untils(test) && same
                latency = (GetSecs - startTime)*1000; 
                return;
            end
            
            % If neither 'until' nor same, then this is an error
            if ~(untils(test) || same)
                latency = (GetSecs - startTime)*1000;
                err(test) = 1;
                return;
            end
        end
    
        % Pause briefly to keep loop running in a reasonable way
        WaitSecs(0.0001);
        
    end
    
    % If we've run through the loop, then there were never any
    % events to trigger an early exit. For 'while' tests, this is
    % desirable and not an error, but for 'until' tests this is an
    % error. Thus, all 'until' tests should be marked as errors.
    err = untils;
      
end





