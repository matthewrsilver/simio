function eyeLinkCommandBuffer(self, func, command)
    
    if ~exist('command', 'var'), command = ''; end
    
    switch func
        case 'add'
            self.eye.commandBuffer = {command self.eye.commandBuffer{:}}; %#ok<CCAT>
        case 'clear'
            self.eye.commandBuffer = {};
    end
end

