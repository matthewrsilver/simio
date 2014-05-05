% Converts degrees to pixels
function px = deg2px(self, deg)
    px = round(tand(deg)*self.screenDistanceCm*self.pxPerCm);
end