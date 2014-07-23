function eyeLinkCommandBuffer(self, func, command)
    
    % Deal with empty command case (clearing, mostly)
    if ~exist('command', 'var'), command = {''}; end
    
    % Convert command to cell array if it isn't one. Allows batch commands
    if ~iscell(command), command = {command}; end
    
    switch func
        case 'add'
            self.eye.commandBuffer = {command{:} self.eye.commandBuffer{:}}; %#ok<CCAT>
        case 'clear'
            self.eye.commandBuffer = {};
    end
end

