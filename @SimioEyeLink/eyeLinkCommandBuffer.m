function eyeLinkCommandBuffer(self, func, command)
    
    if ~exist('command', 'var'), command = ''; end
    
    switch func
        case 'add'
            self.commandBuffer = {commandBuffer{:} command};
        case 'clear'
            self.commandBuffer = {};
    end
end

