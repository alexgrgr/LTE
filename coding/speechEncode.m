function txBits=speechEncode(pcm, law, params)
% MuLawEnc			Convert linear PCM values to Mu-Law or A-Law 8-bit PCM values
%
persistent G7112Bits
if isempty(G7112Bits)
    G7112Bits=comm.IntegerToBit('BitsPerInteger',8,'OutputDataType','logical');
end
if strcmp(law,'A')
    g711 = ALawEnc(pcm, params.AencB, params.AencR);
else
    g711 = MuLawEnc(pcm, params.MuencB, params.MuencR);
end
txBits=step(G7112Bits, g711);