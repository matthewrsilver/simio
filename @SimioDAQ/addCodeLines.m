% Add code lines, specially handled for event codes
function addCodeLines(self, lines, ports)

    % Make sure the number of lines and ports is the same
    assert(length(lines) == length(ports))
    
    % Iterate through the lines and add each
    for cur = 1:length(lines)
        name = ['codeLine' num2str(cur)];
        addline(self.dio, lines(cur), ports(cur), 'out', name);
        self.codeIndices = [self.codeIndices self.dio.(name).index];
    end

end
