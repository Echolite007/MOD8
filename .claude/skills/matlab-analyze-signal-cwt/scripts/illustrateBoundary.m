% Copyright 2026 The MathWorks, Inc.
load boundaryExDisjointSine;
[wtr,f] = cwt(sig,Fs,Boundary="reflection");
wtp = cwt(sig,Fs,Boundary="periodic");
wtz = cwt(sig,Fs,Boundary="zeropad");
tl = tiledlayout(3,1);
nexttile
pcolor(tm,f,abs(wtp),EdgeColor="none")
xticks([])
yscale("log")
ylabel("Frequency (Hz)")
title("Periodic")
nexttile
pcolor(tm,f,abs(wtr),EdgeColor="none")
xticks([])
yscale("log")
ylabel("Frequency (Hz)")
title("Reflection")
nexttile
pcolor(tm,f,abs(wtz),EdgeColor="none")
yscale("log")
title("Zero Padding")
xlabel("Time (s)")
ylabel("Frequency (Hz)")
title(tl,"Scalograms with Different Boundary Extensions")