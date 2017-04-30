%% Simulation configuration
visualizeOn = true;
clear lteReportRateError;
%% init
[params, SNR, stopSimulation]=lteParameterMapping(objValues);
[enb, PDSCH, MCS1]=lteSetParams(0);
[Hsa, Hber, Hconst, Hconst2, EVM, Hsa2]=lteVisualize_init(enb, PDSCH);
%% Simulation loop
n=0;
numBits=0;
while 1
    [params, SNR, stopSimulation]=lteParameterMapping(objValues);
    [enb, PDSCH, MCS1]=lteSetParams(n);
    channel=lteSetChannel(enb, PDSCH, params);
    %% Generate input bits
    txBits =lteGenerateBits(PDSCH);
    %% Run Transceiver (Transmiter-Channel-Receiver)
    [txWaveform, rxWaveform, rxBits, txCW, rxCW ] = ...
       lteTxChRx(txBits, enb, PDSCH, MCS1, channel, SNR);
    %% Perform measurements
    txGrid=lteOFDMDemodulate(enb,txWaveform);
    % Find the closest constellation point to each equalized symbol
    refSym=lteMapRefSym(PDSCH);
    Hconst.ReferenceConstellation=refSym(:);
    if visualizeOn, lteVisualizeChannel; end
    drawnow;
    if stopSimulation
        break  % Stop the simulation
    end
    %% Update metrics (BER, PER, Bit-rate)
    [ber, per, ACK]=lteReportRateError(Hber, txBits, rxBits);
    dataRate=lteBitRate;
    myDialog.DataSet={real(txWaveform(:,1)),real(rxWaveform(:,1))};
    updateMetrics(myDialog, [n, mod2bits(PDSCH.Modulation), PDSCH.TargetCodeRate, per, ber, dataRate] );
    n=n+1;
end
lteResetSimulation;