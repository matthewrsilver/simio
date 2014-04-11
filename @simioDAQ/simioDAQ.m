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
        
        % List the names of lines that have been added
        function lineNames = getLines(self)
            lineNames = self.dio.line.lineName;
        end
        
        % Add a strobe line
        function addStrobeLine(self, line, port)
            addline(self.dio, line, port, 'out', 'strobe');
         
            self.strobeIndex = self.dio.strobe.index;
        end
        
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
        
        % Set event lines and trigger strobe
        function strobeTime = strobeCode(self, decimalCode)
                   
            % If there's no strobe line, or no code lines, just quit
            if isempty(self.strobeIndex) || isempty(self.codeIndices)
                strobeTime = GetSecs;
                return;
            end
            
            % Set the values of the code lines
            numBits = length(self.codeIndices);
            code = fliplr(dec2binvec(decimalCode,numBits));
            
            % Check the length and truncate if needed, but WARN!
            if length(code) > numBits
                code = code(end-numBits+1:end);
                disp('INSUFFICIENT CODE BITS, INFORMATION LOST');
            end
            
            % Put the binary code on the lines
            putvalue(self.dio.Line(self.codeIndices), code)
            
            % Set and reset the value of the strobe line
            putvalue(self.dioudd, true, self.strobeIndex);
            strobeTime = GetSecs;
            WaitSecs(.0005);
            putvalue(self.dioudd, false, self.strobeIndex);
            
            % Set the lines back to 0
            putvalue(self.dio.Line(self.codeIndices), false(1, numBits));
            
        end
            
    end
    
end