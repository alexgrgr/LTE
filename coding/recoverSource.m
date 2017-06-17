function recoverSource(params, rxBits)
% Input information (select a number):
%  1: use random data for transmission
%  2: use sound from microphone for transmission
%  3: use video from webcam for transmission
switch params.mode
    case 2 % Voice
            BitsToSpeech;
            system('RxSpeech.wav');
    case 3 %Video
        myRes = 3;
        useCodegen = true;
        y = BitsToVideo(rxBits, myRes, useCodegen);
        out_vp = vision.VideoPlayer;
        numFrm = numel(y);
        for n=1:10
            for m=1:numFrm
                step(out_vp,y{m});
                pause(0.1);
            end
        end
    otherwise
        fprintf('Recovering from random source is useless\n');
end