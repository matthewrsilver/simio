% Wait for conditions to be met
function [err latency] = wait(self, duration, varargin)

    % Handle timing
    startTime = GetSecs;
    endTime   = startTime + duration/1000;
    latency   = NaN;
    
    % Holders for argument types
    argTypes  = {};
    whileArgs = {};
    untilArgs = {};
    
    % Store the property names and test values associated with
    % while and associated with until
    for arg = 1:3:numel(varargin)
        if strcmp('while', varargin{arg})
            whileArgs = {whileArgs{:} {varargin{arg+1} varargin{arg+2}}};
            argTypes  = {argTypes{:} 'while'};
        else
            untilArgs = {untilArgs{:} {varargin{arg+1} varargin{arg+2}}};
            argTypes  = {argTypes{:} 'until'};
        end
    end
    
    % Use the conditions to set default output values
    err       = ~isempty(untilArgs);
    
    % Now run the loop
    while GetSecs < endTime
        
        % First check 'while' arguments
        failures = ~cellfun(@(x)self.io.(x{1})==x{2}, whileArgs);
        if any(failures)
            latency = (GetSecs - startTime)*1000;
            err     = failures;
            return;
        end
        
        % Now check 'until' arguments
        if ~isempty(untilArgs)
            compliant = cellfun(@(x)self.io.(x{1})==x{2}, untilArgs);
            if all(compliant)
                latency = (GetSecs - startTime)*1000;
                err     = false;
                return;
            else
                err = ~compliant;
            end
        end
        
        % Pause briefly to keep loop running in a reasonable way
        WaitSecs(0.0001);
    end
    
end


% Another implementation, incompatible with multiple tests, but
% that may contain certain improvements...


%         function [err latency] = wait(self, duration, condition, interface, requirement)
%         
%             % Handle timing
%             startTime = GetSecs;
%             endTime   = startTime + duration/1000;
%             
%             % Default outputs
%             latency   = NaN;
%             err       = 0;
%             
%             % Handle the case where we're just waiting
%             if nargin < 3
%                 WaitSecs(endTime-GetSecs)
%                 return;
%             end         
%             
%             % If this is an 'until' call, reverse the logic
%             if strcmp('until', condition)
%                err         = 1;
%                requirement = ~requirement; 
%             end
%             
%             % Run the loop
%             while GetSecs < endTime
%                 if self.io.(interface) ~= requirement
%                     latency = (GetSecs - startTime)*1000;
%                     err     = ~err;
%                     return;
%                 end                 
%             end
%             
%             % Pause briefly to keep loop running in a reasonable way
%             WaitSecs(0.0001);
%             
%         end

