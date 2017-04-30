function br=lteBitRate(numBits, m, params)
%numBits=0;
for n=0:1:m
[~, PDSCH, ~]=lteSetParams(params, n);
numBits=numBits+sum(sum(PDSCH.TrBlkSize));
end
br=100*numBits;
    