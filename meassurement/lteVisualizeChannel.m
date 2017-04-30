
a= txWaveform(:,1);
%a= [txWaveform; zeros(offset,enb.CellRefP)];
a= a(:,1);
b= rxWaveform(:,1);
as = size(a,1);
bs = size(b,1);
if bs > as
    a = [a; zeros((bs-as),1)];
end
if as > bs
    b = [b; zeros((as-bs),1)];
end
step(Hsa,[a, b]);
%%
% pdschIndices = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
% sigA=eqGrid(pdschIndices);
% sigB=rxGrid(pdschIndices);
% a=sigA(:);
% b=sigB(:);
if ~iscell(rxCW)
step(Hconst,rxCW);
else
    NN=size(rxCW,2);
    rxCW2=[];
    for n=1:NN
        rxCW2=[rxCW2; rxCW{n}];
    end
    step(Hconst,rxCW2);
end
 step(Hconst2, b);
release(Hconst); 
 release(Hconst2);
