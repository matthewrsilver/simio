% Get the current eye position
function eyePos = getEyePosition(self)

    % get the sample in the form of an event structure
    samp   = Eyelink('NewestFloatSample');
    eyePos = ceil([samp.gx(self.trackedEyeNum)    ...
                   samp.gy(self.trackedEyeNum)]);
    
    % clean up eye position to ensure it's within bounds. Minimum
    % value must be 1 because eyePos is used downstream as an array
    % index within a window ID map.
    eyePos = max(min(eyePos, self.eyePosBounds), 1);
    
end