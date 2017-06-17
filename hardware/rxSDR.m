function rxWaveform = rxSDR(txInfo, SDRv)
switch SDRv.Radio
    case 'B210'
        %% Receive using USRP B210
        fprintf(' using USRP B210\n');
        samplesPerFrame = 10e-3*txInfo.SamplingRate;
        SDRRx = searchsdr();
        SDRRx.NumFramesInBurst = samplesPerFrame;
        SDR = SDR_rx_init(SDRRx, SDRv, txInfo);
        rxWaveform = zeros(1,1);
        fprintf('Introduce number of reception samples (There are %.0f samples per frame):\n', samplesPerFrame);
        x = input('');
        NumSamples = 0;
        while NumSamples < x
            % Capture a frame
            rxWaveformTmp = step(SDR);
            rxWaveform = [rxWaveform; rxWaveformTmp]; %#ok<AGROW>
            NumSamples = size(rxWaveform,1);
        end
        fprintf('End of reception');
        release(SDR);
        rxWaveform = double(rxWaveform);
        rxWaveform = rxWaveform/max(abs(rxWaveform(:)));
    case 'BladeRF'
        %% Send using BladeRF
        fprintf(' using Nuand BladeRF\n');
        SDRRx = bladeRF();
        SDR_rx_init(SDRRx, SDRv, txInfo);
        samples = input('Introduce number of reception samples\n');
        SDRRx.rx.start();
        % Receives "samples" N of samples with tiemout set to infinite and
        % timestamp set to now
        [rxWaveform, timestamp_out, actual_count, overrun] = SDRRx.receive(samples, 0, 0);
        if overrun~=0
            warning('SDR:DroppedSamples','Dropped samples, only %.0f continuous samples adquired. This PC is not able to adquire all the samples contiguously.', actual_count)
        end
        SDRRx.rx.stop();
        clear SDRRx;
        rxWaveform = rxWaveform(1:actual_count);
    otherwise
        error('The radio selected is not a valid radio. Change the value of params.SDR.radio in setParams.m');
end