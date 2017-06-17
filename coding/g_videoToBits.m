function txBits = g_videoToBits(rgb, myRes)
%#codegen
assert((myRes<=9)&&(myRes>=1));
% Get sizes
payloadLength=getPayloadLength(myRes);
numBitsPerSlice=8*payloadLength;
numBitsPerFrame=3*numBitsPerSlice;
txBits=false(numBitsPerFrame,1);
% Encode now
prev=0;
for k=1:3
    J = rgb(:,:,k);
    K = g_video_encode3(J);
    myBits=g_int2bits(K);
    txBits(prev+(1:numBitsPerSlice))=myBits;
    prev=prev+numBitsPerSlice;
end
end