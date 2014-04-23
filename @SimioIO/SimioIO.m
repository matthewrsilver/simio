classdef SimioIO < dynamicprops
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
        
        % Constructor for SimioIO
        function self = SimioIO(simio)
           
            self.env = simio;
            self.truth.GetMethod = true;
                        
        end
        
        % Destructor for simioIO
        function delete(self)
           
        end
        
    end
    
end