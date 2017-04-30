function [txWaveform, offset, rxWaveform, rxCW] = simulate(frame, txBits, enb, PDSCH, MCS1, channel, txInfo, params)
%% Run Transceiver (Transmiter-Channel-Receiver)
[txWaveform, rxWaveform, rxBits, txCW, rxCW ] = ...
   lteTxChRx(txBits, enb, PDSCH, MCS1, channel, params.SNR);
%% Show Receiving Grid with power for first frame and channel power fadding
%% Perform frame synchronization.
offset = lteDLFrameOffset(enb,rxWaveform);
rxWaveform = rxWaveform(1+offset:end,:);
% Perform OFDM demodulation for first frame
rxGrid = lteOFDMDemodulate(enb,rxWaveform);
% Create a surface plot showing the power of the received grid 
% for each subcarrier and OFDM symbol.
if frame == 1
    figure('Color','w');
    helperPlotReceiveWaveform(txInfo,rxWaveform);
    %%
    if enb.CellRefP == 1
        %helperPlotReceiveResourceGrid(enb,rxGrid);
        figure;
        PlotReceivedResourceGrid(enb,rxGrid);
    end
end

end