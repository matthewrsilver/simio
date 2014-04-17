function fixating = gazeAt(self, location, diameter)
            
    fixating = false;
    
    % get the sample in the form of an event structure
    samp       = Eyelink('NewestFloatSample');
    curEyePos  = ceil([samp.gx(self.trackedEyeNum)    ...
                       samp.gy(self.trackedEyeNum)]);
    
    cuePosition = [self.env.displayCenter(1) + self.env.deg2px(location(1)), ...
                   self.env.displayCenter(2) + self.env.deg2px(location(2))];
    
    curEyeDist = norm(cuePosition - curEyePos);
    
    % Test the distance between the eye position and
    % the center
    if curEyeDist < self.env.deg2px(diameter/2);
        fixating = true;
    end
    
end