classdef simioDAQ < dynamicprops
    %SIMIODAQ DAQ OBJECT FOR USE WITH SIMIO TASK ENVIORONMENT
    %   
   
    properties

        % DigitalIO object
        dio

        % Handle back to simo
        env

        % Strobe related properties
        strobeIndex = []
        codeIndices = [];
    end
        
    properties(GetAccess = public, SetAccess = private, Hidden = true)
        dioudd
    end
    
    methods
        
        % Constructor for simioDAQ
        function self = simioDAQ(env)
        
            % Handle back to simio
            self.env    = env;
            config      = self.env.config; 
    
            % Create the dio object, and open access to the special
            % uddobject for faster daq queries.
            self.dio    = digitalio(config.daqAdaptor, config.daqID);
            self.dioudd = daqgetfield(self.dio, 'uddobject');
            
            % Add fixation line
            if isfield(config, 'daqFixation')
                self.addLine(config.daqFixation(1),      ...
                             config.daqFixation(2),      ...
                             'in',                       ...
                             'fixation');                ...
            end
                         
            % Add lever line
            if isfield(config, 'daqLever')
                self.addLine(config.daqLever(1),         ...
                             config.daqLever(2),         ...
                             'in',                       ...
                             'lever');                   ...
            end
        
            % Add reward line
            if isfield(config, 'daqReward')
                self.addLine(config.daqReward(1),        ...
                             config.daqReward(2),        ...
                             'out',                      ...
                             'reward');                  ...
                         
                % Test the reward line
                for r = 1:3
                    self.reward(true);
                    WaitSecs(.05);
                    self.reward(false);
                    WaitSecs(.05);
                end
            end
                         
            % Add strobe line
            if isfield(config, 'daqStrobe')
                self.addStrobeLine(config.daqStrobe(1),  ...
                                   config.daqStrobe(2)); ...
            end
                               
            % Add code lines
            if isfield(config, 'daqCodes')
                self.addCodeLines(config.daqCodes(:,1),  ...
                                  config.daqCodes(:,2));
                         
                % Test the code lines
                tmp = [1 zeros(1, length(self.codeIndices)-1)];
                for c = 1:length(self.codeIndices)
                    tmp = circshift(tmp, [0 -1]);
                    self.strobeCode(bin2dec(num2str(tmp)));
                    WaitSecs(.05);
                end
            end
        end
        
        % Destructor for simioDAQ
        function delete(self)
            self.releaseDAQ();
        end
        
        % Delete the device object from the engine.
        function releaseDAQ(self)
            %delete(self.dio);
        end
        
        % List the names of lines that have been added
        function lineNames = getLines(self)
            lineNames = self.dio.line.lineName;
        end
                                
    end
    
end