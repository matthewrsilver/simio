% Generate a unique filename for the session
function generateUniqueFileName(self)

    % Generate a filename for the current session, ensuring
    % that no existing files are overwritten.
    nameNeeded = 1;
    nameNumber = 0;
    
    while nameNeeded
        
        putativeName = sprintf('%s-%s-%s-%02d.behavior',               ...
                               self.config.experimentName,             ...
                               self.config.subjectName,                ...
                               datestr(date, 'yyyymmdd'),              ...
                               nameNumber);
        
        % Now check the data directory, specified by dataPath, for any
        % existing files with the putative name
        nameNeeded = exist([self.config.dataPath putativeName], 'file') == 2;
        nameNumber = nameNumber+1;
                
    end
            
    self.config.fileName = putativeName;
    
end

