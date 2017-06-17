function subframes = inputData(params, PDSCH, txInfo)
%% %%%%%%%%%%%% Obtain txBits %%%%%%%%%%%%%%%%%
switch params.mode
    case 1
        %% Random Data
        subframes(PDSCH.TrBlkSize, txInfo.TotSubframes) = 0;
        for n=1:txInfo.TotSubframes
            % Generate input bits for every subframe
            txBits = randi([0, 1], PDSCH.TrBlkSize, 1);
            subframes(:,n)= txBits;
        end
    case 2
        %% Sound. Get from microphone
        Fs=44100;
        FrameSize=427*3;
        SecondsOfSpeech = 2;
        txBitsAll = musicToBits(Fs, FrameSize, SecondsOfSpeech, true);
        % Separate frames from all the stream
        numTotalFrames = ceil(numel(txBitsAll)/PDSCH.TrBlkSize);
        txInfo.TotSubframes =numTotalFrames;
        p= 1;
        subframes(PDSCH.TrBlkSize, txInfo.TotSubframes) = 0;
        for n = 1:txInfo.TotFrames-1
            subframes(:,n)= txBitsAll(p:(p-1) + PDSCH.TrBlkSize);
            p = p + PDSCH.TrBlkSize;
        end
    case 3
        %% Video
        % Initialize webcam
        myRes = 3;
        
        % Acquire video from webcam
        cam = webcam(1);
        choices = cam.availableResolutions;
        myResStr= choices{myRes};
        fprintf(1,'Choice %d,  Resolution %s\n', myRes, myResStr);
        cam.Resolution=myResStr;
        
        %Acquire video data
        numSeconds = 2.5;
        FramesPerSecond = 6;
        numSnapShots = numSeconds*FramesPerSecond;
        y = g_videoAcquire(cam, FramesPerSecond, numSnapShots);
        pause(1);
        % Encode video
        useCodeGen = false;
        txBitsAll = videoToBits(y, myRes, useCodeGen);
        txBitsAll = txBitsAll(:);
        [txy, txpcm] = BitsToVideo(txBitsAll, myRes, useCodeGen);
        vp = vision.VideoPlayer;
        for n=1:15, step(vp,txy{n}); end
        % Encode video
        myRes = 3;
        useCodeGen = true;
        txBitsAll = videoToBits(txy, myRes, useCodeGen);
        txBitsAll = txBitsAll(:);
end