% Converts degrees to pixels
function px = deg2px(self, deg)
    px = round(tand(deg)*self.config.screenDistanceCm*self.pxPerCm);
end