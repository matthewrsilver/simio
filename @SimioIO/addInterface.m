% Add an interface, providing a name, direction, and function
function success = addInterface(self, name, direction, handle)

    % Default to reporting failure...
    success = 0;

    % Ensure that the user isn't trying to create an
    % interface called 'simio' because we can't add
    % a property called simio (already used by handle)
    if strcmp(name, 'simio')
        disp('Interface cannot be called simio');
        return;
    end

    % Add a property used to get the value of this line
    P = self.addprop(name);
            
    % Handle getting/setting
    try
        
        if strcmpi(direction, 'in')
            P.GetMethod = handle;
        elseif strcmpi(direction, 'out')
            P.SetMethod = @(self,x)handle(x);
        end
        
    catch err
        disp(err.message)
        return;
    end
    
    % If we're here, then the property was successfully added, 
    % I think.
    success = 1;
    
end
