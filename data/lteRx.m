function [ crc, rxGrid, eqGrid, enbRx, PDSCHRx, ofdmInfo, rxBits]= lteRx(rxWaveform)
% This fuction receives a signal and demodulates and synchronize it to
% extra information from it, stored in the outputs

%%
% Set Number of resource blocks to minimum. Real information is going to be
% extracted from the frames received.
% The primary and secondary synchronization signals (PSS and SSS) and the
% PBCH (containing the MIB) all lie in the central 72 subcarriers (6 
% resource blocks) of the system bandwidth, allowing the UE to initially 
% demodulate just this central region.
enbRx.NDLRB = 6;
sr = 15.36e6;  % Sampling rate for loaded samples
% plots
if (~exist('channelFigure','var') || ~isvalid(channelFigure))
    channelFigure = figure('Visible','off');
end
[spectrumAnalyzer,synchCorrPlot,pdcchConstDiagram] = ...
    hSIB1RecoveryExamplePlots(channelFigure,sr);
%% PDSCH EVM
pdschEVM = comm.EVM();
pdschEVM.MaximumEVMOutputPort = true;

%% The sampling rate for the initial cell search is established using
% lteOFDMInfo configured for 6 resource blocks. enb.CyclicPrefix is set
% temporarily in the call to lteOFDMInfo to suppress a default value
% warning (it does not affect the sampling rate).
ofdmInfo = lteOFDMInfo(setfield(enbRx,'CyclicPrefix','Normal')); %#ok<SFLD>

if (isempty(rxWaveform))
    fprintf('\nReceived signal must not be empty.\n');
    return;
end

%% Display received signal spectrum
fprintf('\nPlotting received signal spectrum...\n');
spectrumAnalyzer(awgn(rxWaveform, 100.0));

%% Downsample signal for cell search
if (sr~=ofdmInfo.SamplingRate)
    if (sr < ofdmInfo.SamplingRate)
        warning('The received signal sampling rate (%0.3fMs/s) is lower than the desired sampling rate for cell search / MIB decoding (%0.3fMs/s); cell search / MIB decoding may fail.',sr/1e6,ofdmInfo.SamplingRate/1e6);
    end
    fprintf('\nResampling from %0.3fMs/s to %0.3fMs/s for cell search / MIB decoding...\n',sr/1e6,ofdmInfo.SamplingRate/1e6);
else
    fprintf('\nResampling not required; received signal is at desired sampling rate for cell search / MIB decoding (%0.3fMs/s).\n',sr/1e6);
end
% Downsample received signal
nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(rxWaveform,1));
nRxAnts = size(rxWaveform, 2);
downsampled = zeros(nSamples, nRxAnts);
for i=1:nRxAnts
    downsampled(:,i) = resample(rxWaveform(:,i), ofdmInfo.SamplingRate, round(sr));
end

%% Perform Cell ID search on the input waveform and the delay of the
% received signal
% Perform cell search across duplex mode and cyclic prefix length
% combinations and record the combination with the maximum correlation; if
% multiple cell search is configured, this example will decode the first
% (strongest) detected cell
% Set up duplex mode and cyclic prefix length combinations for search; if
% either of these parameters is configured in |enb| then the value is
% assumed to be correct
if (~isfield(enbRx,'DuplexMode'))
    duplexModes = {'TDD' 'FDD'};
else
    duplexModes = {enbRx.DuplexMode};
end
if (~isfield(enbRx,'CyclicPrefix'))
    cyclicPrefixes = {'Normal' 'Extended'};
else
    cyclicPrefixes = {enbRx.CyclicPrefix};
end

fprintf('\nPerforming cell search...\n');
searchalg.MaxCellCount = 1;
searchalg.SSSDetection = 'PostFFT';
peakMax = -Inf;
for duplexMode = duplexModes
    for cyclicPrefix = cyclicPrefixes
        enbRx.DuplexMode = duplexMode{1};
        enbRx.CyclicPrefix = cyclicPrefix{1};
        [enbRx.NCellID, offset, peak] = lteCellSearch(enbRx, downsampled, searchalg);
        enbRx.NCellID = enbRx.NCellID(1);
        offset = offset(1);
        peak = peak(1);
        if (peak>peakMax)
            enbMax = enbRx;
            offsetMax = offset;
            peakMax = peak;
        end
    end
end

% Use the cell identity, cyclic prefix length, duplex mode and timing
% offset which gave the maximum correlation during cell search
enbRx = enbMax;
offset = offsetMax;

%% Compute the correlation for each of the three possible primary cell
% identities; the peak of the correlation for the cell identity established
% above is compared with the peak of the correlation for the other two
% primary cell identities in order to establish the quality of the
% correlation.
corr = cell(1,3);
idGroup = floor(enbMax.NCellID/3);
for i = 0:2
    enbRx.NCellID = idGroup*3 + mod(enbMax.NCellID + i,3);
    [~,corr{i+1}] = lteDLFrameOffset(enbRx, downsampled);
    corr{i+1} = sum(corr{i+1},2);
end
threshold = 1.3 * max([corr{2}; corr{3}]); % multiplier of 1.3 empirically obtained
if (max(corr{1})<threshold)
    warning('Synchronization signal correlation was weak; detected cell identity may be incorrect.');
end
% Return to originally detected cell identity
enbRx.NCellID = enbMax.NCellID;

% Plot PSS/SSS correlation and threshold
synchCorrPlot.YLimits = [0 max([corr{1}; threshold])*1.1];
synchCorrPlot([corr{1} threshold*ones(size(corr{1}))]);

% Perform timing synchronization
fprintf('Timing offset to frame start: %d samples\n',offset);
downsampled = downsampled(1+offset:end,:);
enbRx.NSubframe = 0;

%% Frequency Offset Estimation and Correction
% Prior to OFDM demodulation, any significant frequency offset must be
% removed. The frequency offset in the I/Q waveform is estimated and
% corrected. The frequency offset is estimated by means of correlation of 
% the cyclic prefix and therefore can estimate offsets up to +/- half the 
% subcarrier spacing i.e. +/- 7.5kHz.

fprintf('\nPerforming frequency offset estimation...\n');
% For TDD, TDDConfig and SSC are defaulted to 0. These parameters are not
% established in the system until SIB1 is decoded, so at this stage the
% values of 0 make the most conservative assumption (fewest downlink
% subframes and shortest special subframe).
if (strcmpi(enbRx.DuplexMode,'TDD'))
    enbRx.TDDConfig = 0;
    enbRx.SSC = 0;
end
delta_f = lteFrequencyOffset(enbRx, downsampled);
fprintf('Frequency offset: %0.3fHz\n',delta_f);
downsampled = lteFrequencyCorrect(enbRx, downsampled, delta_f);    

%% OFDM Demodulation and Channel Estimation  
% The OFDM downsampled I/Q waveform is demodulated to produce a resource
% grid |rgrid|. This is used to perform channel estimation. |hest| is the
% channel estimate, |nest| is an estimate of the noise (for MMSE
% equalization) and |cec| is the channel estimator configuration.
%
% For channel estimation the example assumes 4 cell specific reference
% signals. This means that channel estimates to each receiver antenna from
% all possible cell-specific reference signal ports are available. The true
% number of cell-specific reference signal ports is not yet known. The
% channel estimation is only performed on the first subframe, i.e. using
% the first |L| OFDM symbols in |rxgrid|.
%
% A conservative 9-by-9 pilot averaging window is used, in time and
% frequency, to reduce the impact of noise on pilot estimates during
% channel estimation.

% Channel estimator configuration
cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'cubic';             % 2D interpolation type
cec.InterpWindow = 'Centered';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  

% Assume 4 cell-specific reference signals for initial decoding attempt;
% ensures channel estimates are available for all cell-specific reference
% signals
enbRx.CellRefP = 4;   
                    
fprintf('Performing OFDM demodulation...\n\n');

griddims = lteResourceGridSize(enbRx); % Resource grid dimensions
L = griddims(2);                     % Number of OFDM symbols in a subframe 
% OFDM demodulate signal 
rxgrid = lteOFDMDemodulate(enbRx, downsampled);    
if (isempty(rxgrid))
    fprintf('After timing synchronization, signal is shorter than one subframe so no further demodulation will be performed.\n');
    return;
end
% Perform channel estimation for first subframe
[hest, nest] = lteDLChannelEstimate(enbRx, cec, rxgrid(:,1:L,:));

%% PBCH Demodulation, BCH Decoding, MIB Parsing
% The MIB is now decoded along with the number of cell-specific reference
% signal ports transmitted as a mask on the BCH CRC. The function
% ltePBCHDecode establishes frame timing modulo 4 and returns this in the 
% |nfmod4| parameter. It also returns the MIB bits in vector |mib| and the 
% true number of cell-specific reference signal ports which is assigned
% into |enb.CellRefP| at the output of this function call. If the number of
%cell-specific reference signal ports is decoded as |enb.CellRefP=0|, this 
% indicates a failure to decode the BCH. The function lteMIB is used to 
% parse the bit vector |mib| and add the relevant fields to the 
% configuration structure |enb|. After MIB decoding, the detected bandwidth
% is present in |enb.NDLRB|. 

% Decode the MIB
% Extract resource elements (REs) corresponding to the PBCH from the first
% subframe across all receive antennas and channel estimates
fprintf('Performing MIB decoding...\n');
pbchIndices = ltePBCHIndices(enbRx);
[pbchRx, pbchHest] = lteExtractResources( ...
    pbchIndices, rxgrid(:,1:L,:), hest(:,1:L,:,:));

% Decode PBCH
[bchBits, pbchSymbols, nfmod4, mib, enbRx.CellRefP] = ltePBCHDecode( ...
    enbRx, pbchRx, pbchHest, nest); 

% Parse MIB bits
enbRx = lteMIB(mib, enbRx); 

% Incorporate the nfmod4 value output from the function ltePBCHDecode, as
% the NFrame value established from the MIB is the System Frame Number
% (SFN) modulo 4 (it is stored in the MIB as floor(SFN/4))
enbRx.NFrame = enbRx.NFrame+nfmod4;

% Display cell wide settings after MIB decoding
fprintf('Cell-wide settings after MIB decoding:\n');
disp(enbRx);

if (enbRx.CellRefP==0)
    fprintf('MIB decoding failed (enb.CellRefP=0).\n\n');
    return;
end
if (enbRx.NDLRB==0)
    fprintf('MIB decoding failed (enb.NDLRB=0).\n\n');
    return;
end

%% OFDM Demodulation on Full Bandwidth
% Now that the signal bandwidth is known, the signal is resampled to the
% nominal sampling rate used by lteOFDMModulate. Frequency offset 
% vestimation and correction is performed on the resampled signal.
% Timing synchronization and OFDM demodulation are then performed.

fprintf('Restarting now that bandwidth (NDLRB=%d) is known\n',enbRx.NDLRB);

% Resample now we know the true bandwidth
ofdmInfo = lteOFDMInfo(enbRx);
if (sr~=ofdmInfo.SamplingRate)
    if (sr < ofdmInfo.SamplingRate)
        warning('The received signal sampling rate (%0.3fMs/s) is lower than the desired sampling rate for NDLRB=%d (%0.3fMs/s); PDCCH search / SIB1 decoding may fail.',sr/1e6,enbRx.NDLRB,ofdmInfo.SamplingRate/1e6);
    end    
    fprintf('\nResampling from %0.3fMs/s to %0.3fMs/s...\n',sr/1e6,ofdmInfo.SamplingRate/1e6);
else
    fprintf('\nResampling not required; received signal is at desired sampling rate for NDLRB=%d (%0.3fMs/s).\n',enbRx.NDLRB,sr/1e6);
end
nSamples = ceil(ofdmInfo.SamplingRate/round(sr)*size(rxWaveform,1));
resampled = zeros(nSamples, nRxAnts);
for i = 1:nRxAnts
    resampled(:,i) = resample(rxWaveform(:,i), ofdmInfo.SamplingRate, round(sr));
end

% Perform frequency offset estimation and correction
delta_f = lteFrequencyOffset(enbRx, resampled);
fprintf('Frequency offset: %0.3fHz\n',delta_f);
resampled = lteFrequencyCorrect(enbRx, resampled, delta_f);

% Find beginning of frame+
offset = lteDLFrameOffset(enbRx, resampled); 
fprintf('Timing offset to frame start: %d samples\n',offset);
% Aligning signal with the start of the frame
resampled = resampled(1+offset:end,:);   

% OFDM demodulation
rxgrid = lteOFDMDemodulate(enbRx, resampled);   

%% SIB1 Decoding
% The following steps are performed in this section:
%
% * Physical Control Format Indicator Channel (PCFICH) demodulation, CFI
% decoding
% * PDCCH decoding
% * Blind PDCCH search
% * SIB bits recovery: PDSCH demodulation and DL-SCH decoding
% * Buffering and resetting of the DL-SCH HARQ state
%
% After recovery the SIB CRC should be 0.
% 
% These decoding steps are performed in a loop for each occurrence of a
% subframe carrying SIB1 in the received signal. As mentioned above, the
% SIB1 is transmitted in subframe 5 of every even frame, so the input
% signal is first checked to establish that at least one occurrence of SIB1
% is present. For each SIB1 subframe, the channel estimate magnitude
% response is plotted, as is the constellation of the received PDCCH.

% Check this frame contains SIB1, if not advance by 1 frame provided we
% have enough data, terminate otherwise. 
if (mod(enbRx.NFrame,2)~=0)                    
    if (size(rxgrid,2)>=(L*10))
        rxgrid(:,1:(L*10),:) = [];   
        fprintf('Skipping frame %d (odd frame number does not contain SIB1).\n\n',enbRx.NFrame);
    else        
        rxgrid = [];
    end
    enbRx.NFrame = enbRx.NFrame + 1;
end

% Advance to subframe 5, or terminate if we have less than 5 subframes  
if (size(rxgrid,2)>=(L*5))
    rxgrid(:,1:(L*5),:) = [];   % Remove subframes 0 to 4        
else    
    rxgrid = [];
end
enbRx.NSubframe = 5;

if (isempty(rxgrid))
    fprintf('Received signal does not contain a subframe carrying SIB1.\n\n');
end

% Reset the HARQ buffers
decState = [];

% While we have more data left, attempt to decode SIB1
while (size(rxgrid,2) > 0)

    fprintf('SIB1 decoding for frame %d\n',mod(enbRx.NFrame,1024));

    % Reset the HARQ buffer with each new set of 8 frames as the SIB1
    % info may be different
    if (mod(enbRx.NFrame,8)==0)
        fprintf('Resetting HARQ buffers.\n\n');
        decState = [];
    end

    % Extract current subframe
    rxsubframe = rxgrid(:,1:L,:);
    
    % Perform channel estimation
    [hest,nest] = lteDLChannelEstimate(enbRx, cec, rxsubframe);    
    
    %% PCFICH demodulation, CFI decoding. The CFI is now demodulated and
    % decoded using similar resource extraction and decode functions to
    % those shown already for BCH reception. lteExtractResources is used to
    % extract REs corresponding to the PCFICH from the received subframe
    % rxsubframe and channel estimate hest.
    pcfichIndices = ltePCFICHIndices(enbRx);  % Get PCFICH indices
    [pcfichRx, pcfichHest] = lteExtractResources(pcfichIndices, rxsubframe, hest);
    % Decode PCFICH
    cfiBits = ltePCFICHDecode(enbRx, pcfichRx, pcfichHest, nest);
    cfi = lteCFIDecode(cfiBits); % Get CFI
    if (isfield(enbRx,'CFI') && cfi~=enbRx.CFI)
        release(pdcchConstDiagram);
    end
    enbRx.CFI = cfi;
    fprintf('Decoded CFI value: %d\n\n', enbRx.CFI);   
    
    % For TDD, the PDCCH must be decoded blindly across possible values of 
    % the PHICH configuration factor m_i (0,1,2) in TS36.211 Table 6.9-1.
    % Values of m_i = 0, 1 and 2 can be achieved by configuring TDD
    % uplink-downlink configurations 1, 6 and 0 respectively.
    if (strcmpi(enbRx.DuplexMode,'TDD'))
        tddConfigs = [1 6 0];
    else
        tddConfigs = 0; % not used for FDD, only used to control while loop
    end    
    alldci = {};
    while (isempty(alldci) && ~isempty(tddConfigs))
        % Configure TDD uplink-downlink configuration
        if (strcmpi(enbRx.DuplexMode,'TDD'))
            enbRx.TDDConfig = tddConfigs(1);
        end
        tddConfigs(1) = [];        
        % PDCCH demodulation. The PDCCH is now demodulated and decoded
        % using similar resource extraction and decode functions to those
        % shown already for BCH and CFI reception
        pdcchIndices = ltePDCCHIndices(enbRx); % Get PDCCH indices
        [pdcchRx, pdcchHest] = lteExtractResources(pdcchIndices, rxsubframe, hest);
        % Decode PDCCH and plot constellation
        [dciBits, pdcchSymbols] = ltePDCCHDecode(enbRx, pdcchRx, pdcchHest, nest);
        pdcchConstDiagram(pdcchSymbols);

        % PDCCH blind search for System Information (SI) and DCI decoding.
        % The LTE System Toolbox provides full blind search of the PDCCH to
        % find any DCI messages with a specified RNTI, in this case the
        % SI-RNTI.
        pdcch = struct('RNTI', 65535);  
        pdcch.ControlChannelType = 'PDCCH';
        pdcch.EnableCarrierIndication = 'Off';
        pdcch.SearchSpace = 'Common';
        pdcch.EnableMultipleCSIRequest = 'Off';
        pdcch.EnableSRSRequest = 'Off';
        pdcch.NTxAnts = 1;
        alldci = ltePDCCHSearch(enbRx, pdcch, dciBits); % Search PDCCH for DCI                
    end
    
    % If DCI was decoded, proceed with decoding PDSCH / DL-SCH
    for i = 1:numel(alldci)
        
        dci = alldci{i};
        fprintf('DCI message with SI-RNTI:\n');
        disp(dci);
        % Get the PDSCH configuration from the DCI
        [PDSCHRx, trblklen] = hPDSCHConfiguration(enbRx, dci, pdcch.RNTI);
        
        % If a PDSCH configuration was created, proceed with decoding PDSCH
        % / DL-SCH
        if ~isempty(PDSCHRx)
            
            PDSCHRx.NTurboDecIts = 5;
            fprintf('PDSCH settings after DCI decoding:\n');
            disp(PDSCHRx);

            % PDSCH demodulation and DL-SCH decoding to recover SIB bits.
            % The DCI message is now parsed to give the configuration of
            % the corresponding PDSCH carrying SIB1, the PDSCH is
            % demodulated and finally the received bits are DL-SCH decoded
            % to yield the SIB1 bits.

            fprintf('Decoding SIB1...\n\n');        
            % Get PDSCH indices
            [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enbRx, PDSCHRx, PDSCHRx.PRBSet);
            [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsubframe, hest);
            % Decode PDSCH 
            [dlschBits,pdschSymbols] = ltePDSCHDecode(enbRx, PDSCHRx, pdschRx, pdschHest, nest);
            % Decode DL-SCH with soft buffer input/output for HARQ combining
            if ~isempty(decState)
                fprintf('Recombining with previous transmission.\n\n');
            end        
            [sib1, crc, decState] = lteDLSCHDecode(enbRx, PDSCHRx, trblklen, dlschBits, decState);

            % Compute PDSCH EVM
            recoded = lteDLSCH(enbRx, PDSCHRx, pdschIndicesInfo.G, sib1);
            remod = ltePDSCH(enbRx, PDSCHRx, recoded);
            [~,refSymbols] = ltePDSCHDecode(enbRx, PDSCHRx, remod);
            [rmsevm,peakevm] = pdschEVM(refSymbols{1}, pdschSymbols{1});
            fprintf('PDSCH RMS EVM: %0.3f%%\n',rmsevm);
            fprintf('PDSCH Peak EVM: %0.3f%%\n\n',peakevm);

            fprintf('SIB1 CRC: %d\n',crc);
            if crc == 0
                fprintf('Successful SIB1 recovery.\n\n');
            else
                fprintf('SIB1 decoding failed.\n\n');
            end
            
        else
            % Indicate that creating a PDSCH configuration from the DCI
            % message failed
            fprintf('Creating PDSCH configuration from DCI message failed.\n\n');
        end
        
    end
    if (numel(alldci)==0)
        % Indicate that DCI decoding failed 
        fprintf('DCI decoding failed.\n\n');
    end
    
    % Update channel estimate plot 
    figure(channelFigure);
    surf(abs(hest(:,:,1,1)));
    hSIB1RecoveryExamplePlots(channelFigure);
    channelFigure.CurrentAxes.XLim = [0 size(hest,2)+1];
    channelFigure.CurrentAxes.YLim = [0 size(hest,1)+1];   
    
    % Skip 2 frames and try SIB1 decoding again, or terminate if we
    % have less than 2 frames left. 
    if (size(rxgrid,2)>=(L*20))
        rxgrid(:,1:(L*20),:) = [];   % Remove 2 more frames
    else
        rxgrid = []; % Less than 2 frames left
    end
    enbRx.NFrame = enbRx.NFrame+2;
        
end
%% Demodulation and channel estimation for all frames
rxGrid = lteOFDMDemodulate(enbRx, resampled);  
[estChannel, noiseEst] = lteDLChannelEstimate(enbRx,cec,rxGrid);

%% The effects of the channel on the received resource grid are equalized 
% using lteEqualizeMMSE. This function uses the estimate of the channel 
% estChannel and noise noiseEst to equalize the received resource grid 
% rxGrid. The function returns eqGrid which is the equalized grid. The 
% dimensions of the equalized grid are the same as the original transmitted
% grid (txGrid) before OFDM modulation.

eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);

% Perform deprecoding, layer demapping, demodulation and
% descrambling on the received data using the estimate of the channel
% PDSCHRx.CSI = 'On'; % Use soft decision scaling
switch enbRx.CyclicPrefix
    case 'Normal'
        NSym = 14;
    case 'Extended'
        NSym = 12;
end
TotSubframes = size(rxGrid,2)/NSym;
enbRx.NSubframe = 0;
[rxEncodedBits, rxCW] = ltePDSCHDecode(enbRx, PDSCHRx,...
                        rxGrid(:,1:14,:),estChannel,noiseEst);
% 
%% Decode DownLink Shared Channel (DL-SCH)
PDSCHRx.NTurboDecIts = 5;
if iscell(rxEncodedBits) && ~iscell(PDSCHRx.Modulation)
   [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, trblklen,...
                      rxEncodedBits{1});
else
   [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, trblklen,...
                      rxEncodedBits);
end
rxBits = cell2mat(rxBitsTmp);
for n=1:TotSubframes-1
    enbRx.NSubframe = n;
    [rxEncodedBits, rxCW] = ltePDSCHDecode(enbRx, PDSCHRx,...
                          rxGrid(:,14*n+1:14*n+14,:), estChannel,noiseEst);
    % 
    %% Decode DownLink Shared Channel (DL-SCH)
    % PDSCHRx.NTurboDecIts = 5;
    if iscell(rxEncodedBits) && ~iscell(PDSCHRx.Modulation)
       [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, trblklen,...
                        rxEncodedBits{1});
    else
       [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, trblklen,...
                        rxEncodedBits);
    end
    rxBits = [rxBits; cell2mat(rxBitsTmp)]; %#ok<AGROW>
end
