function [target, latency] = waitTargetAcquired(self, duration, map)

    % Handle timing
    startTime = GetSecs;
    endTime   = startTime + duration/1000;
    
    % Default outputs
    latency   = NaN;
    target    = 0;
    
    % Run the loop
    while GetSecs < endTime
        
        % Get the window associated with the current eye position
        window = self.eye.getGazeWindow(map);
        
        % If the window is not the null window (0)...
        if window
            latency = (GetSecs - startTime)*1000;
            target  = window;
            return
        end
        
    end
    
    % Pause briefly to keep loop running in a reasonable way
    WaitSecs(0.0001);
end
