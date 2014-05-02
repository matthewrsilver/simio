function draw(self, drawStr, varargin)

    switch drawStr
        case 'texture'
            drawTexture(varargin{:});
        case 'rect'
            drawRect(varargin{:});
        case 'cue'
            drawCue(varargin{:});
        case 'fixation'
            drawFixation(varargin{:});
        otherwise
            disp('WARNING: Unrecognized draw type. Nothing drawn.')
    end

    
    % Draws a stored texture on the screen, default to eye center
    function drawTexture(textureHandle, varargin)
            
        % Get the size of the texture
        if isempty(varargin)
            tSize = self.ptb.textures(textureHandle);
        else
            tSize = varargin{1};
        end
            
        % Create a rect to define the screen position
        destRect  = [self.displayCenter(1) - round(tSize(1)/2),   ...
                     self.displayCenter(2) - round(tSize(2)/2),   ...
                     self.displayCenter(1) + round(tSize(1)/2),   ...
                     self.displayCenter(2) + round(tSize(2)/2)];

        % Add this texture to the eyelink command buffer
        if self.config.autoDrawEyeLink
            self.eye.eyeLinkCommandBuffer('add', sprintf('draw_box %d %d %d %d 15', destRect)) 
        end
        
        % Draw the texture
        Screen('DrawTexture', self.ptb.windowPtr, textureHandle, [], destRect);
    end

    % Draw a rectangle to the screen
    function drawRect(color, position)

        % Add this rect to the eyelink command buffer
        if self.config.autoDrawEyeLink
            for r = 1:size(position, 1)
                self.eye.eyeLinkCommandBuffer('add', sprintf('draw_box %d %d %d %d 15', position(1,:))) 
            end           
        end

        
        Screen('FillRect', self.ptb.windowPtr, color, position);
        
    end



    function drawCue(location, diameter, color)
           
        if ~exist('color', 'var')
           color = self.config.cueColor; 
        end
        
        cueCenter = [self.displayCenter(1) + self.deg2px(location(1)), ...
                     self.displayCenter(2) + self.deg2px(location(2))];
        
        % Create a rect to define the screen position
        destRect  = [cueCenter(1) - round(diameter/2),   ...
                     cueCenter(2) - round(diameter/2),   ...
                     cueCenter(1) + round(diameter/2),   ...
                     cueCenter(2) + round(diameter/2)];

        % Add this cue to the eyelink command buffer
        if self.config.autoDrawEyeLink
            self.eye.eyeLinkCommandBuffer('add', sprintf('draw_cross %d %d 15', cueCenter)) 
        end

        
        Screen('FillOval', self.ptb.windowPtr,           ...
               color, destRect, diameter);
                        
    end


    % Draws a circular fixation point at the eye center
    function drawFixation(diameter)
            
        % Create a rect to define the screen position
        destRect  = [self.displayCenter(1) - round(diameter/2),   ...
                     self.displayCenter(2) - round(diameter/2),   ...
                     self.displayCenter(1) + round(diameter/2),   ...
                     self.displayCenter(2) + round(diameter/2)];
            
        % Draw the circle on the screen
        Screen('FillOval', self.ptb.windowPtr, ...
               self.config.fixationPointColor, ...
               destRect, diameter);

        
        % Add this cue to the eyelink command buffer
        if self.config.autoDrawEyeLink
            self.eye.eyeLinkCommandBuffer('add', sprintf('draw_cross %d %d 15', self.displayCenter)) 
        end

        
    end






end

