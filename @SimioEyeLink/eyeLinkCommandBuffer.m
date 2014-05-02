function eyeLinkCommandBuffer(self, func, command)
    
    if ~exist('command', 'var'), command = ''; end
    
    switch func
        case 'add'
            self.commandBuffer = {self.commandBuffer{:} command}; %#ok<CCAT>
        case 'clear'
            self.commandBuffer = {};
    end
end

