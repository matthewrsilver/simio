% Makes a texture to be stored on the GPU for fast drawing
function h = makeTexture(self, image)  
    h = Screen('MakeTexture', self.ptb.windowPtr, image);
    self.ptb.textures(h) = size(image);
end

