clear variables;
addpath(genpath([cd, '\coding']));
addpath(genpath([cd, '\data']));
addpath(genpath([cd, '\hardware']));
addpath(genpath([cd, '\measurement']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set modes
% Type (select a number):
%       1 - Simulation
%       2 - Transmission
%       3 - Reception
params.type = 3;
% In case of transmission or reception, please select a number for the 
% device to use:
%       1 - R&S Instrument
%       2 - URSP or BladeRF SDR
params.device = 2;
% Input information (select a number):
%  1: use random data for transmission
%  2: use sound from microphone for transmission
%  3: use video from webcam for transmission
params.mode = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%    Don´t forget to edit the parameters at data/setParams.m    %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start of the program
if (params.type == 1 || params.type == 2)
    %% Base Station and Physical Downlink Shared Channel Info
    [enb, PDSCH, params]= setParams(params, 0);
    %% For convenience in some functions:
    txInfo = txInfoConformation(PDSCH, enb, params);
    %% Show Resource Blocks Grid before transmission
    showGrid(enb, PDSCH);
    %% Initialize measurement
    % measures(enb, PDSCH, MCS1, params.channel);
    %% Prepare user data to be transmitted
    subframes = inputData(params, PDSCH, txInfo);  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation mode
switch params.type
    case 1
        switch params.WaveMod
            % There are different processes for 4G and 5G
            case'CPOFDM'
                [txWaveform, ~, txGrid]= ...
                    lteTx(txInfo, enb, subframes, params);
                [rxGrid, eqGrid, rxWaveform, txGrid, rxBits] = ...
                    lteSimulate(txWaveform, enb, PDSCH, txInfo, params, txGrid);
            case 'FOFDM'
                [rxGrid, eqGrid, rxWaveform, txGrid, rxBits] = ...
                    FiveGSimulate(enb, PDSCH, txInfo, params, subframes);
            case 'UFMC'
                [rxGrid, eqGrid, rxWaveform, txGrid, rxBits] = ...
                    FiveGSimulate(enb, PDSCH, txInfo, params, subframes);
            otherwise
                error('Error in params.WaveMod: not a valid waveform modulation');
        end    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Transmition Loop
    case 2
        fprintf('Transmision Mode');
         switch params.WaveMod
            case'CPOFDM'
                txWaveform= lteTx(txInfo, enb, subframes, params);
                % This is the name the file on the SMBV100A will have
                fileName = 'LTE';
            case 'FOFDM'
                txWaveform = FiveGTx(params, 1, subframes); 
                for n=2:txInfo.TotSubframes
                    txWaveformTmp = FiveGTx(params, n, subframes);
                    txWaveform = [txWaveform; txWaveformTmp]; %#ok<*AGROW>
                end
                % This is the name the file on the SMBV100A will have
                fileName = 'FOFDM_LTE';
            case 'UFMC'
                txWaveform = FiveGTx(params, 1, subframes); 
                for n=2:txInfo.TotSubframes
                    txWaveformTmp = FiveGTx(params, n, subframes);
                    txWaveform = [txWaveform; txWaveformTmp];
                end
                % This is the name the file on the SMBV100A will have
                fileName = 'UFMC_LTE';
             otherwise
                error('Error in params.WaveMod: not a valid waveform modulation');
         end
        %txWaveform is an OFDM modulated waveform, returned as a numeric 
        % matrix of size T-by-P, where P is the number of antennas and T is
        % the number of time-domain samples. T = K × 30720 / 2048 × Nfft 
        % where Nfft is the IFFT size and K is the number of subframes in
        % the input grid. So txWaveform will have a collumn for each 
        % anthenna, containing all subframes
        switch params.device 
            case 1
                txRS(txWaveform, params, txInfo, fileName);
            case 2
                txSDR(txWaveform, params.SDR, txInfo);
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Receiving Loop
    case 3
        [enb, PDSCH, params]= setParams(params, 0);
        txInfo = txInfoConformation(PDSCH, enb, params);
        fprintf('Receiving Mode');
        switch params.device 
            case 1
                %% Receive using RTO2044
                rxWaveform = rxRS(params);
            case 2
                % Receive with SDR
                rxWaveform = rxSDR(txInfo, params.SDR);
        end
        switch params.WaveMod
            case 'CPOFDM'
                [crc, rxGrid, eqGrid, enbRx, PDSCHRx, rxInfo, rxBits]=...
                    lteRx(rxWaveform);
            case 'FOFDM'
                rxGrid = FiveGReception(rxWaveform, enb, params.WaveMod);
                [crc, eqGrid, rxBits] = FiveGRx(rxGrid, enb, PDSCH);
            case 'UFMC'
                rxGrid = FiveGReception(rxWaveform, enb, params.WaveMod);
                [crc, eqGrid, rxBits] = FiveGRx(rxGrid, enb, PDSCH);
            otherwise
                error('Error in params.WaveMod: not a valid waveform modulation');
        end
        %% Plot Received Waveform
        figure('Color','w');
        PlotReceivedWaveform(txInfo.SamplingRate, rxWaveform);
        %% Plot the received and equalized resource grids for first frame
        % Plot received grid
        hPlotDLResourceGrid(enbRx,rxGrid);
        % Plot equalized received grid
        hPlotDLResourceGrid(enbRx,eqGrid);
        %% Recover original Data
        recoverSource (params, rxBits);
end