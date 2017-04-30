function showGrid(enb,PDSCH)
%% Compute and visualize all control indices 
% Visualization
colors = ones(lteDLResourceGridSize(enb));
% Modulate the PDCCH and compute the indices for it
pdcchIndices = ltePDCCHIndices(enb, {'1based'});
% Map PDCCH to the grid
% Visualization
colors(pdcchIndices) = 6;

%% Add Cell-Specific Reference Signals
% Generate the indices
cellRSIndices = lteCellRSIndices(enb);
% Visualization
colors(cellRSIndices) = 2;
%% Add BCH
if mod(enb.NSubframe,10) == 0
   pbchIndices = ltePBCHIndices(enb);
   % Visualization
   colors(pbchIndices) = 3;
end
%% Add the synchronization signals
% Generate synchronization signals
pssInd = ltePSSIndices(enb);
sssInd = lteSSSIndices(enb);
% Map synchronization signals to the grid
% Visualization
colors(pssInd) = 4;
colors(sssInd) = 4;
%% Add the CFI
% Generate the indices
pcfichIndices = ltePCFICHIndices(enb);
% Map CFI to the grid
% Visualization
colors(pcfichIndices) = 7;
%% Add the PHICH
% Generate the indices
phichIndices = ltePHICHIndices(enb);
% Visualization
colors(phichIndices) = 8;
%% Add the PDSCH
% Generate the transport block(s) indices
[pdschIndices,~] = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
% Visualization
colors(pdschIndices) = 5;
%% Display
hGridDisplay(colors);
end
