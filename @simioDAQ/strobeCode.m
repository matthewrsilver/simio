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
