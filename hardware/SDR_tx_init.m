function radioTx = SDR_tx_init(SDRTx, SDRv, txInfo)
% Intializes the selected radio in setParams.m, along with its parameters 
% on the same location.

switch SDRv.Radio
    case 'B210'
        SDRTx.MasterClockRate = 1.92e6*4;
        % Radio values on lteSetParams
        SDRTx.CenterFrequency    = SDRv.CenterFrequency;
        SDRTx.Gain               = SDRv.RadioGain;
        SDRTx.InterpolationFactor = 2.*round((SDRTx.MasterClockRate/txInfo.SamplingRate)/2);

        switch txInfo.CellRefP
            case 1
                SDRTx.Channel = 1;
            case 2
                SDRTx.Channel = [1 2];
            otherwise
                error('La radio USRP B210 no es capaz de transmitir por más de dos antenas. Cambie el valor de enb.CellRefP en setParams.m');
        end

        % Set up transmitter radio object to use the found radio
        switch SDRTx.Platform
          case {'B200','B210'}
            radioTx = comm.SDRuTransmitter(...
                'Platform',             SDRTx.Platform, ...
                'SerialNum',            SDRTx.Address, ...
                'MasterClockRate',      SDRTx.MasterClockRate, ...
                'CenterFrequency',      SDRTx.CenterFrequency,...
                'Gain',                 SDRTx.Gain, ...
                'InterpolationFactor',  SDRTx.InterpolationFactor,...
                'UnderrunOutputPort',   true,...
                'ChannelMapping',       SDRTx.Channel);
          case {'X300','X310'}
            radioTx = comm.SDRuTransmitter(...
                'Platform',             SDRTx.Platform, ...
                'IPAddress',            SDRTx.Address, ...
                'MasterClockRate',      SDRTx.MasterClockRate, ...
                'CenterFrequency',      SDRTx.CenterFrequency,...
                'Gain',                 SDRTx.Gain, ...
                'InterpolationFactor',  SDRTx.InterpolationFactor,...
                'NumFramesInBurst',     SDRTx.NumFramesInBurst,...
                'EnableBurstMode',      false);
          case {'N200/N210/USRP2'}
            radioTx = comm.SDRuTransmitter(...
                'Platform',             SDRTx.Platform, ...
                'IPAddress',            SDRTx.Address, ...
                'CenterFrequency',      SDRTx.CenterFrequency,...
                'Gain',                 SDRTx.Gain, ...
                'InterpolationFactor',  SDRTx.InterpolationFactor,...
                'NumFramesInBurst',     SDRTx.NumFramesInBurst,...
                'EnableBurstMode',      false);
        end
    case 'BladeRF'
        SDRv.MasterClockRate = 1.92e6*4; %20000000;  %Hz
        SDRTx.tx.frequency =  SDRv.CenterFrequency;
        SDRTx.tx.samplerate = txInfo.SamplingRate;%2.*round((SDRv.MasterClockRate/txInfo.SamplingRate)/2);
        % Possible values for BladeRF transceiver bandwidth are:
        % 1.5, 1.75, 2.5, 2.75, 3, 3.84, 5, 5.5, 6, 7, 8.75, 10, 12, 14, 
        % 20 or 28 MHz
        switch txInfo.NDLRB
            case 6
                SDRTx.tx.bandwidth = 1.5e6;
            case 15
                SDRTx.tx.bandwidth =3e6;
            case 25
                SDRTx.tx.bandwidth = 5e6;
            case 50
                SDRTx.tx.bandwidth = 10e6;
            case 75
                SDRTx.tx.bandwidth = 20e6;
            case 100
                SDRTx.tx.bandwidth = 20e6;
        end
        SDRTx.tx.vga1 = SDRv.RadioGain;
        SDRTx.tx.vga2 = 5;
        radioTx = 1;
end
