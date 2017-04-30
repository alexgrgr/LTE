function simulate1(txWaveform, subframes, enb, PDSCH, MCS1, channel, txInfo, params) %#ok<INUSL>
% Set channel parameters
channel= lteSetChannel(txInfo, PDSCH);
%% Apply Channel modeling
rxWaveform= lteCh(txWaveform,enb,channel,params.SNR, txInfo);
[rxBits, rxCW, crc, rxGrid, eqGrid, enbRx]= lteRx(rxWaveform, PDSCH);

% Calculate error between transmitted and equalized grid

%% Compute EVM across all input values
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

% Plot the received and equalized resource grids
% Plot received grid error on logarithmic scale
    figure;
    dims = size(rxGrid(:,1:(14*10),:));
    surf(20*log10(abs(rxGrid(:,1:(14*10),:))));
    title('Received first frame resource grid');
    ylabel('Subcarrier');
    xlabel('Symbol');
    zlabel('dB');
    axis([1 dims(2) 1 dims(1) -40 10]);

    % Plot equalized grid error on logarithmic scale
    figure;
    surf(20*log10(abs(eqGrid(:,1:(14*10),:))));
    title('Equalized first frame resource grid');
    ylabel('Subcarrier');
    xlabel('Symbol');
    zlabel('absolute value (dB)');
    axis([1 dims(2) 1 dims(1) -40 10]);
end
