function [rgb, pcm]=g_BitsToVideo(rxBits, myRes)
%#codegen
assert((myRes<=9)&&(myRes>=1));
% Get sizes right
payloadLength=getPayloadLength(myRes);
numBitsPerSlice=8*payloadLength;
[newR, newC]=getRowsColumns(payloadLength);
rgb=uint8(zeros(16*newR, 16*newC, 3));
%%
prev3=0;
tmp=uint8(zeros(payloadLength,3));
for k=1:3
    Bits=rxBits(prev3+(1:numBitsPerSlice));
    K=g_bits2int(Bits);
    tmp(:,k)=K;
    L= g_video_decode3(K);
    rgb(:,:,k)=L;
    prev3=prev3+numBitsPerSlice;
end
pcm=tmp(:);
