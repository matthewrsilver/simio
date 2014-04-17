% Add a strobe line
function addStrobeLine(self, line, port)
    addline(self.dio, line, port, 'out', 'strobe');
    self.strobeIndex = self.dio.strobe.index;
end
