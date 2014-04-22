classdef simioIO < dynamicprops
    %SIMIOIO
    %   
   
    properties
        
        % Handle back to simio
        env
       
    end
    
    properties(Hidden = true)
        dioudd
        truth
    end

    methods
        
        % Constructor for simioIO
        function self = simioIO(simio)
           
            self.env = simio;
            self.truth.GetMethod = true;
                        
        end
        
        % Destructor for simioIO
        function delete(self)
           
        end
        
    end
    
end