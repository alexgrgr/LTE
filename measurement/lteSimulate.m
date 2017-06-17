function [rxGrid, eqGrid, rxWaveform, txGrid, rxBits] = lteSimulate(txWaveform, enb, PDSCH, txInfo, params, txGrid)
 
%% Set channel parameters
params = lteSetChannel(txInfo, PDSCH, params);

%% Apply Channel modeling
rxWaveform= lteCh(txWaveform, enb, params.channel, txInfo, params.channel.condition);

%% Plot Received Waveform
figure('Color','w');
PlotReceivedWaveform(txInfo.SamplingRate, rxWaveform);

%% Demodulate and Synchronize Signal
[~, rxGrid, eqGrid, enbRx, ~, ~, rxBits]= lteRx(rxWaveform);
    
%% Calculate error between transmitted and equalized grid
% Compute EVM across all input values
% EVM of pre-equalized receive signal
EVM = comm.EVM;
EVM.AveragingDimensions = [1 2];
preEqualisedEVM = EVM(txGrid,rxGrid);
fprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', ...
        preEqualisedEVM);
% EVM of post-equalized receive signal
postEqualisedEVM = EVM(txGrid,eqGrid);
fprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', ...
        postEqualisedEVM);

%% Plot the received and equalized resource grids for first frame
% Plot received grid
hPlotDLResourceGrid(enbRx,rxGrid);
% Plot equalized received grid
hPlotDLResourceGrid(enbRx,eqGrid);

%% Plot Spectrogram
% Compute spectrogram
[~,f,t,p] = spectrogram(rxWaveform, 512, 0, 512, rxInfo.SamplingRate);  

% Re-arrange frequency axis and spectrogram to put zero frequency in the
% middle of the axis i.e. represent as a complex baseband waveform
f = (f-txInfo.SamplingRate/2)/1e6;
p = fftshift(10*log10(abs(p)));

% Plot spectrogram
figure;
surf(t*1000,f,p,'EdgeColor','interp');   
xlabel('Time (ms)');
ylabel('Frequency (MHz)');
zlabel('Power (dB)');
title(sprintf('Spectrogram of received signal'));
clear f t p;
end
