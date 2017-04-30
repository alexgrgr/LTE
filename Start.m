clear variables;
addpath(genpath([cd, '\coding']));
addpath(genpath([cd, '\data']));
addpath(genpath([cd, '\hardware']));
addpath(genpath([cd, '\import']));
addpath(genpath([cd, '\meassurement']));
%% Set modes
% Type (select a number):
%       1 - Simulation
%       2 - Transmission
%       3 - Reception
params.type = 1;
% In case of transmission or reception, please select a number for the 
% device to use:
%       1 - R&S Instrument
%       2 - URSP SDR
params.device = 1;
% Input information (select a number):
%  1: use random data for transmission
%  2: use sound from microphone for transmission
params.mode = 1;


%% Base Station and Physical Downlink Shared Channel Info
[enb, PDSCH, MCS1, params, SDRv]= lteSetParams(params, 0);
%% For convenience in some functions:
txInfo = txInfoConformation(PDSCH, enb, params);
%% Show Resource Blocks Grid before transmission
showGrid(enb, PDSCH);

%% Initialize measurement and visualization objects
visualizeOn = true;
%clear lteReportRateError lteBitRate;
[Hsa, Hber, Hconst, Hconst2, EVM, Hsa2]=lteVisualize_init(PDSCH, txInfo);
% meassures(enb, PDSCH, MCS1, channel);

%% %%%%%%%%%%%% Obtain txBits %%%%%%%%%%%%%%%%%
if params.mode == 1
    %% Random Data
    subframes(PDSCH.TrBlkSize, txInfo.TotSubframes) = 0;
    for n=1:txInfo.TotSubframes
        % Generate input bits for every subframe
        txBits = randi([0, 1], PDSCH.TrBlkSize, 1);
        subframes(:,n)= txBits;
    end
    clear txBits n;
end
if params.mode == 2
    %% Sound. Get from microphone
    Fs=44100;
    FrameSize=427*3;
    SecondsOfSpeech = 2;
    txBitsAll = musicToBits(Fs, FrameSize, SecondsOfSpeech, true);
    % Separate frames from all the stream
    numTotalFrames = ceil(numel(txBitsAll)/PDSCH.TrBlkSize);
    txInfo.TotSubframes =numTotalFrames;
    p= 1;
    subframes(PDSCH.TrBlkSize, txInfo.TotSubframes) = 0;
    for n = 1:txInfo.TotFrames-1
        subframes(:,n)= txBitsAll(p:(p-1) + PDSCH.TrBlkSize);
        p = p + PDSCH.TrBlkSize;
    end
    clear Fs FrameSize SecondsOfSpeech numTotalFrames txBitsAll p n;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation mode
if params.type == 1
    %% Channel Information
    [txWaveform, ~ , txCW]= lteTx1(txInfo, enb, subframes, params);
    simulate1(txWaveform, subframes, enb, PDSCH, MCS1, channel, txInfo, params);

    %     % Simulate Channel and create plots
%     for n= 1:txInfo.TotFrames
%         [enb, PDSCH, MCS1]=lteSetParams(params, n);
%         txBits = frames(:,n);
%         [txWaveform, offset, rxWaveform, rxCW] = simulate(n, txBits, enb, PDSCH, MCS1, channel, txInfo, params);
%         % Find the closest constellation point to each equalized symbol
%         refSym=lteMapRefSym(PDSCH);
%         Hconst.ReferenceConstellation=refSym(:);
%         %% Draw each Subframe
%         if visualizeOn, lteVisualizeChannel; end
%         drawnow;
%     end
end
%% Transmition Loop
if params.type == 2
    fprintf('Transmision Mode\n');
    [txWaveform, ~ , txCW]= lteTx1(txInfo, enb, subframes, params);
    %txWaveform is an OFDM modulated waveform, returned as a numeric matrix 
    % of size T-by-P, where P is the number of antennas and T is the number
    % of time-domain samples. T = K � 30720 / 2048 � Nfft where Nfft is the
    % IFFT size and K is the number of subframes in the input grid. 
    % So txWaveform will have a collumn for each anthenna, containing
    % all subframes

    if params.device == 1
        %% Send using SMBV100A
        fprintf(' Using R&S SMBV100A\n');
        % Instrument values on lteSetParams
        % Sending only antenna 1 using Send to SMBV100A Toolbox
        % Send to SMBV100A Toolbox is a custom toolbox that must be
        % installed too.
        % Note that possibly not all samples will be transmitted.
        % Hardware limitations specified at Send to SMBV100A Toolbox 
        % Documentation
        send_to_RS('LTE', txInfo.SamplingRate,...
                    real(txWaveform(:,1)),... % Treated as I
                    imag(txWaveform(:,1)),... % Treated as Q
                    params.fc, params.power); % Tx frequecy and power
    end
        
    if params.device == 2
        %% Send using USRP B210
        % Scale signal to make maximum magnitude equal to 1
        eNodeB = txWaveform/max(abs(txWaveform(:)));
        % Reshape signal as a 3D array to simplify the for loop below
        % Each call to step method of the object will use a two-column matrix
%         samplesPerFrame = 10e-3*txInfo.SamplingRate;      % LTE frames are 10 ms long
%         numFrames = length(eNodeB)/samplesPerFrame;
%         txFrame = permute(reshape(permute(eNodeB,[1 3 2]), ...
%                           samplesPerFrame,numFrames,enb.CellRefP),[1 3 2]);

        fprintf(' Using USRP B210\n');
        SDRTx = searchsdr();
        SDR = SDR_tx_init(SDRTx, SDRv, txInfo);
        x = input('Introduce transmiting time in seconds\n');
        time = tic;
        while toc(time) <= x
            for n=1:size(txWaveform,2)
                bufferUnderflow = SDR(txWaveform(:,n));
                if bufferUnderflow~=0
                    warning('SDR:DroppedSamples','Dropped samples')
                end
            end
        end
        release(SDR);
        fprintf('End of transmission');
        clear time x;
    end
end
%% Receiving Loop
if params.type == 3
    fprintf('Receiving');
%% Send using USRP B210
spectrumAnalyzer = dsp.SpectrumAnalyzer;
spectrumAnalyzer.SampleRate = txInfo.SamplingRate;  % 1.92e6 MHz for 'R.12'
spectrumAnalyzer.Title = 'Potencia recibida';
spectrumAnalyzer.ShowLegend = true;

fprintf(' Using USRP B210');
SDRRx = searchsdr();
SDR = SDR_rx_init(SDRRx);
n = 1;
x = input('Introduce receiving time in seconds\n');
time = tic;
while toc(time) <= x
    % Capture a frame
    TemprxWaveform = step(SDR);
    rxWaveform = [rxWaveform; TemprxWaveform];
    % Plot on the spectrum analyzer
    step(spectrumAnalyzer, rxWaveform);
    [rxBits, rxCW ]= lteRx(rxWaveform, enb, PDSCH);
    rxBitsAll = [rxBitsAll; rxBits];
end
release(spectrumAnalyzer);
fprintf('End of transmission');
release(SDR);
end