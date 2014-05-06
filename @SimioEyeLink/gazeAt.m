function fixating = gazeAt(self, location, diameter)
            
    fixating = false;
    
    % get the sample in the form of an event structure
    samp       = Eyelink('NewestFloatSample');
    curEyePos  = ceil([samp.gx(self.eye.trackedEyeNum)    ...
                       samp.gy(self.eye.trackedEyeNum)]);
    
    cuePosition = [self.displayCenter(1) + self.deg2px(location(1)), ...
                   self.displayCenter(2) + self.deg2px(location(2))];
    
    curEyeDist = norm(cuePosition - curEyePos);
    
    % Test the distance between the eye position and
    % the center
    if curEyeDist < self.deg2px(diameter/2);
        fixating = true;
    end
    
end