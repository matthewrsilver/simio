function setTaskFunctions(self, varargin)

    % Extract inputs, setting SimioEnv properties according
    % to name-value pairs
    for arg = 1:2:numel(varargin)
        switch lower(varargin{arg})
          
          % Deal with trial function handles 
          case 'trial'
            if isa(varargin{arg+1}, 'function_handle')
                self.trialHandle     = varargin{arg+1};
            else
                disp(['The value supplied for ''trial''' ...
                      'is not a function handle']);
            end
                
          % Deal with preTrial function handles
          case {'pre', 'pretrial'}
            if isa(varargin{arg+1}, 'function_handle')
                self.preTrialHandle  = varargin{arg+1};
            else
                disp(['The value supplied for ''preTrial''' ...
                      'is not a function handle']);
            end
            
          % Deal with postTrial function handles
          case {'post', 'posttrial', 'postrial'}
            if isa(varargin{arg+1}, 'function_handle')
                self.postTrialHandle  = varargin{arg+1};
            else
                disp(['The value supplied for ''postTrial''' ...
                      'is not a function handle']);
            end

          otherwise
            disp([varargin{arg} ' is not a valid parameter']);
        end
    end

end