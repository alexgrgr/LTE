function rxWaveform = lteCh(txWaveform, enb, channel, txInfo)  

%% Channel Model
% Apply Channel Fading adding zeros for later syncronization without
% loosing data
[rxWaveform,~] = lteFadingChannel(channel, txWaveform);

%% Additive WGN
% Convert dB to linear
SNR = 10^(txInfo.SNR/20);

% Normalize noise power to take account of sampling rate, which is
% a function of the IFFT size used in OFDM modulation, and the 
% number of antennas
N0 = 1/(sqrt(2.0*enb.CellRefP*double(txInfo.Nfft))*SNR);

% Create additive white Gaussian noise
noise = N0*complex(randn(size(rxWaveform)), ...
                    randn(size(rxWaveform)));

% Add AWGN to the received time domain waveform
rxWaveform = rxWaveform + noise;
