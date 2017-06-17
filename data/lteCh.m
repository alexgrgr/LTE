function rxWaveform = lteCh(txWaveform, enb, channel, txInfo, condition)  
% Generates a channel model specified in setParams.m and pass the signal 
% throught it. Then, an Aditive White Gaussian Noise is added.
%% Channel Models
% b3.2 - Multipath-fading MIMO conditions as of 3GPP TS 36.104 Annex B.2
% b3.3 - High speed train conditions as of 3GPP TS 36.104 Annex B.3
% b3.4 - Moving propagation conditions as of 3GPP TS 36.104 Annex B.4

% Apply Channel Fading adding zeros for later syncronization without
% loosing data
switch condition
    case 'b2'
        rxWaveform = lteFadingChannel(channel, txWaveform);
    case 'b3'
        rxWaveform = lteHSTChannel(channel, txWaveform);
    case 'b4'
        rxWaveform = lteMovingChannel(channel, txWaveform);
    otherwise
        error('Error in params.channel.type: Not a valid channel type');
end
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
