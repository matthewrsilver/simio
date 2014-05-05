% Display the menu and wait for keypresses
function quit = osdMenu(self)

    % By default, don't quit!
    quit     = 0;
    drawMenu = 1;
    
    % Clear keypresses
    FlushEvents('keyDown');
    
    % Loop forever in the menu until the user requests otherwise
    while true
        
        % Draw the menu if required
        if drawMenu
            % Draw the menu on the OSD and flip.
            self.updateOSD({'[r] to resume';            ...
                            '[c] to calibrate';         ...
                            '[v] to modify a variable'; ...
                            '[q] to quit'});
            self.flip(self.codes.displayUpdate);
            drawMenu = 0;
        end
        
        % If a key has been pressed, handle it
        if CharAvail
            switch GetChar(1)
              case 'r'
                break;
              case 'c'
                if ~isempty(self.eye)
                    self.calibrate();
                    drawMenu = 1;
                end
                continue;
              case 'v'
                % wish I could hide task window
                continue;
              case 'q'
                quit = 1;
                return;
            end
        end
    end
    
    % Update the OSD and flush keystrokes to resume the task
    FlushEvents('keyDown');
    self.updateOSD(self.currentTrial.osdText);
    self.flip(self.codes.displayUpdate);
    
end
