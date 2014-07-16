% Get the current status of fixation, for use with simioIO
function fixating = fixation(self)

    % Set default output to false
    fixating = false;
    
    % get the sample in the form of an event structure
    samp       = Eyelink('NewestFloatSample');
    curEyePos  = ceil([samp.gx(self.eye.trackedEyeNum)    ...
                       samp.gy(self.eye.trackedEyeNum)]);
    
    %Slight timing improvement (~.01ms) from avoiding use of norm
    %curEyeDist = norm(self.displayCenter - curEyePos);
    curEyeDist = sqrt(sum([self.displayCenter - curEyePos].^2));
    
    % Test the distance between the eye position and
    % the center
    if curEyeDist < self.eye.fixWindowRadius
        fixating = true;
    end
    
end