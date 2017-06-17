function [y, pcmAll]=BitsToVideo(rxBitsAll, myRes, useCodegen)
numBitsPerFrame=24*getPayloadLength(myRes);
numFrames = ceil(numel(rxBitsAll)/numBitsPerFrame);
numPaddedSamples =numBitsPerFrame*numFrames-numel(rxBitsAll);
if numPaddedSamples > 0
    rxBitsAll=[rxBitsAll;false(numPaddedSamples,1)];
end
rxBitsAll=logical(reshape(rxBitsAll, numBitsPerFrame, numFrames));
tmp=uint8(zeros(3*getPayloadLength(myRes), numFrames));
for n=1:numFrames
    rxBits=rxBitsAll(:,n);
    if useCodegen
        [rgbOut, pcm]=g_BitsToVideo_mex(rxBits, myRes);
    else
        [rgbOut, pcm]=g_BitsToVideo(rxBits, myRes);
    end
    tmp(:,n)=pcm;
    y{n}=rgbOut;
end
pcmAll=tmp(:);
