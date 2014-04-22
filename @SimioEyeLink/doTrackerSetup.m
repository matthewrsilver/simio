function result = doTrackerSetup(self, sendkey)
% DOTRACKERSETUP Run the EyeLink calibration routine through PsychToolbox 
%
% This code is largely excerpted from Psychtoolbox and modified to
% work well with simio.
    
    % Get the PsychToolbox EyeLink settings struct and set return default
    el     = self.settings;
    result = -1;
            
    Eyelink('Command', 'heuristic_filter = ON');
    Eyelink( 'StartSetup' );		                   
    
    % Time for mode change
    Eyelink( 'WaitForModeReady', el.waitformodereadytime); 
            
    EyelinkClearCalDisplay(el);
    
    % Dump old keys
    key=1;
    while key~= 0, key=EyelinkGetKey(el); end
            
    % Go directly into a particular mode
    if nargin==2
        if el.allowlocalcontrol==1
            switch lower(sendkey)
              case{ 'c', 'v', 'd', el.ENTER_KEY}
                %forcedkey=BITAND(sendkey(1,1),255);
                forcedkey=double(sendkey(1,1));
                Eyelink('SendKeyButton', forcedkey, 0, el.KB_PRESS );
            end
        end
    end
            
    stop=0;
    while stop==0 && bitand(Eyelink( 'CurrentMode'), el.IN_SETUP_MODE)
        
        i=Eyelink( 'CurrentMode');
        
        if ~Eyelink( 'IsConnected' ) stop=1; break; end;
        
        % calibrate, validate, etc: show targets
        if bitand(i, el.IN_TARGET_MODE)			
            targetModeDisplay();
            
        % display image until we're back
        elseif bitand(i, el.IN_IMAGE_MODE)		
            if Eyelink ('ImageModeDisplay')==el.TERMINATE_KEY
                result=el.TERMINATE_KEY;
                return;    % breakout key pressed
            else
                EyelinkClearCalDisplay(el);
            end
        end
        
        % getkey() HANDLE LOCAL KEY PRESS
        [key, el]=EyelinkGetKey(el);
        
        % print pressed key codes and chars
        if false && key~=0 && key~=el.JUNK_KEY    
            fprintf('%d\t%s\n', key, char(key) );
        end
        
        
        switch key
          case el.TERMINATE_KEY,	   % breakout key code
            result=el.TERMINATE_KEY;
            return;
          case { 0, el.JUNK_KEY }          % No or uninterpretable key
          case el.ESC_KEY,
            if Eyelink('IsConnected') == el.dummyconnected
                stop=1; % instead of 'goto exit'
            end
            if el.allowlocalcontrol==1
                Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
            end
          otherwise, 		           % Echo to tracker for remote control
            if el.allowlocalcontrol==1
                Eyelink('SendKeyButton', double(key), 0, el.KB_PRESS );
            end
        end
    end % while IN_SETUP_MODE
    
    % exit:
    EyelinkClearCalDisplay(el);	
    result=0;
    return;
    
    
    
    function result = targetModeDisplay()
        
        % initialize
        result        = -1; 
        targetvisible = 0;	    
        targetrect    = [0 0 0 0];
        
        tx  =el.MISSING;
        ty  =el.MISSING;
        otx =el.MISSING;             % current target position
        oty =el.MISSING;
        
        EyelinkClearCalDisplay(el);
        
        % Dump old keys
        key=1;
        while key~= 0, [key, el]=EyelinkGetKey(el); end
        
        % Not sure why this is required, but detect when the target
        % is not visible (i.e. there are no targets left to present
        % during calibration), and send the escape signal
        % automatically.  Are there consequences for this??
        %[targetsRemain, ~, ~] = Eyelink( 'TargetCheck');
        % better solution, below....
        
        % LOOP WHILE WE ARE DISPLAYING TARGETS
        stop=0;
        while stop==0 && bitand(Eyelink('CurrentMode'), el.IN_TARGET_MODE)
            
            if Eyelink( 'IsConnected' )==el.notconnected
                result=-1;
                return;
            end;
            
            % getkey() HANDLE LOCAL KEY PRESS
            [key, el]=EyelinkGetKey(el);		
            
            switch key
              case el.TERMINATE_KEY,            % breakout key code
                EyelinkClearCalDisplay(el);     % clear_cal_display();
                result=el.TERMINATE_KEY;
                return;
              case el.SPACE_BAR,	    	% 32: accept fixation
                if el.allowlocaltrigger==1
                    Eyelink('AcceptTrigger');
                    self.env.goodMonkey(2, 50, 30, self.env.codes.reward);
                end
                break;
              case { 0,  el.JUNK_KEY	}	% No key
              case el.ESC_KEY,
                if Eyelink('IsConnected') == el.dummyconnected
                    stop=1;
                end
                if el.allowlocalcontrol==1
                    Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
                end
              otherwise,                        % Echo to tracker for remote control
                if el.allowlocalcontrol==1
                    Eyelink('SendKeyButton', key, 0, el.KB_PRESS );
                end
            end 
            
            % HANDLE TARGET CHANGES
            [result, tx, ty]= Eyelink('TargetCheck');
            
            % erased or moved: erase target
            if (targetvisible==1 && result==0) || tx~=otx || ty~=oty
                EyelinkEraseCalTarget(el, targetrect);
                targetvisible = 0;
            end
            
            % redraw if invisible
            if targetvisible==0 && result==1
                targetrect=EyelinkDrawCalTarget(el, tx, ty);
                targetvisible = 1;
                otx = tx;		        % record position for future tests
                oty = ty;
                if el.targetbeep==1
                    EyelinkCalTargetBeep(el);	% optional beep to alert subject
                end
            end
                        
        end % while IN_TARGET_MODE
        
        
        % Clean up on exit
        if el.targetbeep==1
            if Eyelink('CalResult')==1  
                EyelinkCalDoneBeep(el, 1);
            else
                EyelinkCalDoneBeep(el, -1);
            end
        end
        
        % erase target on exit, bit superfluous actually
        if targetvisible==1
            EyelinkEraseCalTarget(el, targetrect);   
        end
        EyelinkClearCalDisplay(el); 
        
        result=0;
        return;
        
    end    
            
end