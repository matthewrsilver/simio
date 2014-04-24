classdef Simio < SimioEnv
%SIMIO Environment for monkey training
%   Simio has three essential functions. To detect external events such
%   as lever presses and eye movements though a DAQ and through
%   ethernet, to display stimuli on the screen using PsychToolbox, and
%   to mark important times with event codes through the DAQ.
   
    methods
        
        % Constructor for the simio class
        function self = Simio(varargin)
           
            % Add the config directory to the path 
            addpath([fileparts(mfilename('fullname')) filesep 'config'])
   
            % Extract user configuration information, and merge
            % with default information in config dir
            for arg = 1:2:numel(varargin)
                switch varargin{arg}
                    case 'config'
                        tmpConf = Simio.userConfig(varargin{arg+1});
                    case 'codes'
                        tmpCode = Simio.userCodes(varargin{arg+1});
                    otherwise
                        disp([varargin{arg} ' is not a valid parameter']);
                end
            end

            % Inherit SimioEnv
            self@SimioEnv('config', tmpConf, 'codes', tmpCodes);
            
        end
              
    end
    
    methods(Static)
        
        % Add user-supplied config information, overriding defaults
        function mergeConfig = userConfig(newConfig)
            
            % Load the default config
            mergeConfig = default_config;
                
            % Get the field names from the user supplied config
            names = fieldnames(newConfig);
            
            % Iterate through the field names, and add to config
            for field = 1:numel(names)
                mergeConfig.(names{field}) = newConfig.(names{field});
            end
            
        end
        
        % Add user-supplied config information, overriding defaults
        function mergeCodes = userCodes(newCodes)
            
            % Load the default codes
            mergeCodes = default_codes;
                
            % Get the field names from the user supplied config
            names = fieldnames(newCodes);
            
            % Iterate through the field names, and add to config
            for field = 1:numel(names)
                mergeCodes.(names{field}) = newCodes.(names{field});
            end
            
        end
        
    end
end

