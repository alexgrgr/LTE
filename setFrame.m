function [enb] = setFrame(enb, subframeNr)
%% Define the PDSCH parameters
% This value will change for every subframe (every frame sent)
% Subframe number between 0 and 9
enb.NSubframe = mod(subframeNr,10);
enb.NFrame = floor(subframeNr/10);
