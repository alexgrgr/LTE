function txRS(txWaveform, params, txInfo, fileName)
% Transmits signal txWaveform throught the SMBV100A vector signal generator

%% Send using SMBV100A
fprintf(' using R&S SMBV100A\n');
% Instrument values on lteSetParams
% Sending only antenna 1 using Send to SMBV100A Toolbox
% Send to SMBV100A Toolbox is a custom toolbox that must be
% installed too.
% Note that possibly not all samples will be transmitted.
% Hardware limitations specified at Send to SMBV100A Toolbox 
% Documentation
sendRS(fileName, txInfo.SamplingRate,...
                real(txWaveform(:,1)),... % Treated as I
                imag(txWaveform(:,1)),... % Treated as Q
                   params.SMBV100A.fc,... % Tx frequecy
                  params.SMBV100A.power); % Tx Power
% clear fileName n txWaveformTmp;