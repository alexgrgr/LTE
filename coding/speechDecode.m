function pcm = speechDecode(rxBits, law, params)
% MuLawEnc			Convert linear PCM values to Mu-Law or A-Law 8-bit PCM values
% 

Bits2G711=comm.BitToInteger('BitsPerInteger',8,'OutputDataType','double');

g711=step(Bits2G711, rxBits);
if strcmp(law,'A')
    pcm = ALawDec(g711, params.Adec);
else
    pcm = MuLawDec(g711, params.Mudec);
end