function [rxGrid, eqGrid, rxWaveform, txGrid, rxBits] = FiveGSimulate(enb, PDSCH, txInfo, params, subframes)
%% First subframe
%% Set channel parameters
params = lteSetChannel(txInfo, PDSCH, params);
% Transmit and receive every subframe separately.
%% Generate first subframe
[txWaveform, txGrid] = FiveGTx(params, txInfo, 1, subframes);
%% Apply Channel modeling
rxWaveform= lteCh(txWaveform,enb, params.channel, txInfo, params.channel.condition);
%% Demodulate and Synchronize Signal
rxGrid = FiveGReception(rxWaveform, enb, params.WaveMod);
%% The rest of subframes
for n=2:txInfo.TotSubframes
    %% Generate one subframe
    [txWaveform, txGridTmp] = FiveGTx(params, txInfo, n, subframes);
    %% Apply Channel modeling
    rxWaveformTmp= lteCh(txWaveform,enb, params.channel, txInfo, params.channel.condition);
    %% Demodulate and Synchronize Signal
    rxGridTmp = FiveGReception(rxWaveformTmp, enb, params.WaveMod);
    % Create grid for total received
    txGrid = [txGrid txGridTmp]; %#ok<*AGROW>
    rxGrid = [rxGrid rxGridTmp];
    rxWaveform = [rxWaveform; rxWaveformTmp];
end
% Extract info from total
[~, eqGrid, enbRx, rxBits] = FiveGRx(rxGrid, enb, PDSCH, params, txInfo);
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
[~,f,t,p] = spectrogram(rxWaveform, 512, 20, 512, txInfo.SamplingRate);  

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
