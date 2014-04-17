% Add a digital line
function addLine(self, line, port, direction, name)

    % Add the line to the dio object
    addline(self.dio, line, port, direction, name);
        
    % Add a property used to get the value of this line
    self.addprop(name);
    
    % Handle getting/setting
    if strcmpi(direction, 'in')
        %P.GetMethod = @(x)getvalue(self.dioudd, self.dio.(name).index);
        self.(name) = @(x)getvalue(self.dioudd, self.dio.(name).index)== true;
        self.env.io.addInterface(name, direction, self.(name));
        
    elseif strcmpi(direction, 'out')
        %P.SetMethod = @(self,x)putvalue(self.dioudd, x, self.dio.(name).index);
        self.(name) = @(x)putvalue(self.dioudd, x, self.dio.(name).index);
        self.env.io.addInterface(name, direction, self.(name));
    end
    
end