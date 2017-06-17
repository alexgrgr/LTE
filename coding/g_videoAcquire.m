function y= g_videoAcquire(cam,FramesPerSecond, numSnapShots )
fprintf(1,'\nPlease look at webcam! \n');
%%
delta=1/FramesPerSecond;
thresh=mySecond+delta;
for n=1:numSnapShots
    x=snapshot(cam);
    y{n}=x;
    while mySecond <= thresh, end;
    thresh=mySecond+delta;
    image(x);
    drawnow;
end
end
% Helper function
function y=mySecond
zeit=clock;
y=60*zeit(5)+zeit(6);
end