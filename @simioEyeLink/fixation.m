% Get the current status of fixation, for use with simioIO
function fixating = fixation(self)

    % Set default output to false
    fixating = false;
    
    % get the sample in the form of an event structure
    samp       = Eyelink('NewestFloatSample');
    curEyePos  = ceil([samp.gx(self.trackedEyeNum)    ...
                       samp.gy(self.trackedEyeNum)]);
    curEyeDist = norm(self.env.displayCenter - curEyePos);
    
    % Test the distance between the eye position and
    % the center
    if curEyeDist < self.fixWindowRadius
        fixating = true;
    end
    
end