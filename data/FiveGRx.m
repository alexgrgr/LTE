function [crc, eqGrid, enbRx, PDSCHRx, rxBits]= FiveGRx(rxgrid, enbRx, params, txInfo)


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
[hest, nest] = lteDLChannelEstimate(enbRx, cec, rxgrid);
    
% Update channel estimate plot 
channelFigure.CurrentAxes.XLim = [0 size(hest,2)+1];
figure(channelFigure);
surf(abs(hest(:,:,1,1)));
    
%% Decode PDSCH 
% Perform deprecoding, layer demapping, demodulation and
% descrambling on the received data using the estimate of the channel
PDSCH.CSI = 'On'; % Use soft decision scaling
[rxEncodedBits, rxCW] = ltePDSCHDecode(enb,PDSCH,rxSubframe,hest,nest);

PDSCH.NTurboDecIts = 5;
if iscell(rxEncodedBits) && ~iscell(PDSCH.Modulation)
   [rxBits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits{1});
else
   [rxBits,crc] = lteDLSCHDecode(enb,PDSCH,PDSCH.TrBlkSize,rxEncodedBits);
end
% % Compute PDSCH EVM
% recoded = lteDLSCH(enbRx, PDSCHRx, pdschIndicesInfo.G, sib1);
% remod = ltePDSCH(enbRx, PDSCHRx, recoded);
% [~,refSymbols] = ltePDSCHDecode(enbRx, PDSCHRx, remod);
% [rmsevm,peakevm] = pdschEVM(refSymbols{1}, pdschSymbols{1});
% fprintf('PDSCH RMS EVM: %0.3f%%\n',rmsevm);
% fprintf('PDSCH Peak EVM: %0.3f%%\n\n',peakevm);

% The effects of the channel on the received resource grid are equalized 
% using lteEqualizeMMSE. This function uses the estimate of the channel 
% estChannel and noise noiseEst to equalize the received resource grid 
% rxGrid. The function returns eqGrid which is the equalized grid. The 
% dimensions of the equalized grid are the same as the original transmitted
% grid (txGrid) before OFDM modulation.

eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);


