% Makes a texture to be stored on the GPU for fast drawing
function h = makeTexture(self, image)  

    % Initialize PTB window if one is not already in place
    if ~self.windowInitialized
        self.initWindow();
    end

    % Make the texture and add it to the PTB window
    h = Screen('MakeTexture', self.ptb.windowPtr, image);
    self.ptb.textures(h) = size(image);
end

