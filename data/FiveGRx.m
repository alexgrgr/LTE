function [crc, eqGrid, rxBits]= FiveGRx(rxGrid, enbRx, PDSCHRx)
% Receives an LTE downlink resource grid that have beeen modulated in one
% of the 5G candidates waveforms, FOFDM or UFMC. It creates graph and
% extracts information for analysis.

%% Plot, sizing and positioning
res = get(0,'ScreenSize');
if (res(3)>1280)
    xpos = fix(res(3)*[1/2 3/4]);
    ypos = fix(res(4)*[1/16 1/2]);
    xsize = xpos(2) - xpos(1) - 20;
    ysize = fix(xsize * 5 / 6);
    repositionPlots = true;
else
    repositionPlots = false;%% Generate one subframe
end
sr = 15.3e6;
% Received signal spectrum
spectrumAnalyzer = dsp.SpectrumAnalyzer();
spectrumAnalyzer.Name = 'Received signal spectrum';
spectrumAnalyzer.SampleRate = sr;
spectrumAnalyzer.ReducePlotRate = false;
spectrumAnalyzer.PlotMaxHoldTrace = true;
spectrumAnalyzer.PlotMinHoldTrace = true;
spectrumAnalyzer.ShowGrid = true;
if (repositionPlots)
    spectrumAnalyzer.Position = [xpos(1) ypos(2) xsize ysize];
end

% Channel magnitude response
channelFigure.Name = 'Channel magnitude response';
channelFigure.NumberTitle = 'off';
channelFigure.Color = [40 40 40]/255;   
channelFigure.Visible = 'off';
if (repositionPlots)
    channelFigure.Position = [xpos(1) ypos(1) xsize ysize];      
end

% %% PDSCH EVM
% pdschEVM = comm.EVM();
% pdschEVM.MaximumEVMOutputPort = true;
% 
%% For channel estimation a conservative 9-by-9 pilot averaging window is 
% used, in time and frequency, to reduce the impact of noise on pilot
% estimates during channel estimation.

% Channel estimator configuration
cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'cubic';             % 2D interpolation type
cec.InterpWindow = 'Centered';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  

% Perform channel estimation for first subframe
[estChannel, noiseEst] = lteDLChannelEstimate(enbRx, cec, rxGrid);
    
% Update channel estimate plot 
% channelFigure.CurrentAxes.XLim = [0 size(estChannel,2)+1];
figure(channelFigure);
surf(abs(estChannel(:,:,1,1)));
    

% The effects of the channel on the received resource grid are equalized 
% using lteEqualizeMMSE. This function uses the estimate of the channel 
% estChannel and noise noiseEst to equalize the received resource grid 
% rxGrid. The function returns eqGrid which is the equalized grid. The 
% dimensions of the equalized grid are the same as the original transmitted
% grid (txGrid) before OFDM modulation.

eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);

%% Decode PDSCH 
% Perform deprecoding, layer demapping, demodulation and
% descrambling on the received data using the estimate of the channel
PDSCHRx.CSI = 'On'; % Use soft decision scaling
TotSubframes = size(rxGrid,2)/14;
enbRx.NSubframe = 0;
[rxEncodedBits, rxCW] = ltePDSCHDecode(enbRx, PDSCHRx,...
                        rxGrid(:,1:14,:), estChannel, noiseEst);
% 
%% Decode DownLink Shared Channel (DL-SCH)
PDSCHRx.NTurboDecIts = 5;
if iscell(rxEncodedBits) && ~iscell(PDSCHRx.Modulation)
   [rxBits,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, PDSCHRx.TrBlkSize,...
                      rxEncodedBits{1});
else
   [rxBits,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, PDSCHRx.TrBlkSize,...
                      rxEncodedBits);
end
%rxBits = cell2mat(rxBitsTmp);
for n=1:TotSubframes-1
    enbRx.NSubframe = n;
    [rxEncodedBits, rxCW] = ltePDSCHDecode(enbRx, PDSCHRx,...
                          rxGrid(:,14*n+1:14*n+14,:), estChannel,noiseEst);
    % 
    %% Decode DownLink Shared Channel (DL-SCH)
    % PDSCHRx.NTurboDecIts = 5;
    if iscell(rxEncodedBits) && ~iscell(PDSCHRx.Modulation)
       [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, PDSCHRx.TrBlkSize,...
                        rxEncodedBits{1});
    else
       [rxBitsTmp,crc, ~] = lteDLSCHDecode(enbRx, PDSCHRx, PDSCHRx.TrBlkSize,...
                        rxEncodedBits);
    end
    rxBits = [rxBits; rxBitsTmp];%cell2mat(rxBitsTmp)]; %#ok<AGROW>
end


