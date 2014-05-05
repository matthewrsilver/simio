% Flip the screen, returning a timestamp
function [timestamp, strobeTimes] = flip(self, codes)

    if self.config.autoDrawEyeLink
       self.eyeLinkDraw('buffer');
    end
    
    % Strobe codes before flip, to ensure accurate
    % post-flip timing (ie. reaction times)
    strobeTimes = self.strobeCodes(codes);
    timestamp   = Screen('Flip', self.ptb.windowPtr, 0, 1);
end

