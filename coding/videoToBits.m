function txBitsAll = videoToBits(y, myRes, useCodegen)
numFrames = size(y,2);
txBitsAll=false(24*getPayloadLength(myRes), numFrames);
for n=1:numFrames
    rgb=y{n};
    if useCodegen
        txBits = g_videoToBits_mex(rgb, myRes);
    else
        txBits = g_videoToBits(rgb, myRes);
    end
    txBitsAll(:,n)=txBits;
end