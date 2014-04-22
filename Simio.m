classdef Simio < SimioEnv
%SIMIO Environment for monkey training
%   Simio has three essential functions. To detect external events such
%   as lever presses and eye movements though a DAQ and through
%   ethernet, to display stimuli on the screen using PsychToolbox, and
%   to mark important times with event codes through the DAQ.
    
    properties
        
    end

    methods
        
        % Constructor for the simio class
        function self = Simio(varargin)
           
            self@SimioEnv(varargin);
            
        end
        
    end
end

