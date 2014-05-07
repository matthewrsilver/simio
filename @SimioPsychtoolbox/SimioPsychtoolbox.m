classdef SimioPsychtoolbox < handle
% SIMIOPSYCHTOOLBOX Class used in mix-in to endow SimioEnv with PTB tools
    
    properties
       
        ptb
        display
        displayCenter
        osdRect
        taskRect
        pxPerCm
        screenDistanceCm
        
    end

    methods
   
        function self = SimioPsychtoolbox(config)
           
            % Extract information about screens
            self.display          = Screen('Resolution', config.screen);
            pxPerCmWidth          = self.display.width/config.screenWidthCm;
            pxPerCmHeight         = self.display.height/config.screenHeightCm;
            self.pxPerCm          = mean([pxPerCmWidth pxPerCmHeight]);
            self.screenDistanceCm = config.screenDistanceCm;
            
            % Warn if pixels aren't square (based on measurements)
            if abs(pxPerCmWidth-pxPerCmHeight) > .1
                disp('WARNING: Pixels not square. Measure monitor in cm.')
            end
            
            % Find the center of the screen from the subject perspective
            eyeCenterYCm       =   config.screenHeightCm     ...
                                 + config.screenElevationCm  ...
                                 - config.eyeElevationCm;
            eyeCenterX         = round(self.display.width/2);
            eyeCenterY         = round(eyeCenterYCm*self.pxPerCm);
            self.displayCenter = [eyeCenterX eyeCenterY]; 
            
            % Prepare to write text using the fastest renderer
            Screen('Preference', 'TextRenderer',    0);
            Screen('Preference', 'DefaultFontSize', 14);
                                    
            % Specify a key name map.  PTB says to do this
            KbName('UnifyKeyNames');
            
            % Set up other psychtoolbox stuff
            self.ptb.textures = containers.Map('KeyType',   'int32',   ... 
                                               'ValueType', 'any');

            % Set rects for osd and task area
            self.osdRect  = [0                  0                       ...
                             self.display.width config.osdHeight];
                         
            self.taskRect = [0                  config.osdHeight   ...
                             self.display.width self.display.height];
            
        end
                
    end
    
end
