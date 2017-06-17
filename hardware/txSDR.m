function txSDR(txWaveform, SDRv, txInfo)
% Transmits txWaveform throught the SDR specified at setParams.m. It
% divides the signal in the lenght of a subframe (1ms), trying to minimize
% the USB asynchronous problem.

% Scale signal to make maximum magnitude equal to 1
eNodeB = txWaveform/max(abs(txWaveform(:)));
% Reshape signal as a 3D array to simplify the for loop below. Each
% call to step method of the object will use a two-column matrix
samplesPerFrame = 10e-3*txInfo.SamplingRate;% LTE frames are 10 ms long
%samplesPerFrame = 10e-3*(((enb.NDLRB*12)/size(txInfo.CyclicPrefixLengths,2))*3.84e6);% LTE frames are 10 ms long
numFrames = length(eNodeB)/samplesPerFrame;
% Reduce number of samples to create complete frames at least
% compliant in time lenght
numFrames = floor (numFrames);
eNodeB = eNodeB(1:numFrames*samplesPerFrame,:);
txFrame = permute(reshape(permute(eNodeB,[1 3 2]), ...
           samplesPerFrame,floor(numFrames),txInfo.CellRefP),[1 3 2]);
switch SDRv.Radio
    case 'B210'
        %% Send using USRP B210
        fprintf(' using USRP B210\n');
        SDRTx = searchsdr();
        SDRTx.NumFramesInBurst = samplesPerFrame;
        SDR = SDR_tx_init(SDRTx, SDRv, txInfo);
        x = input('Introduce transmiting time in seconds\n');
        time = 0;
        while time < x
           for n=1:numFrames
                bufferUnderflow = SDR(txFrame(:,:,n));
                if bufferUnderflow~=0
                    warning('SDR:DroppedSamples','Dropped samples, decrease number of samples per second by decreasing bandwith or using a lower modulation scheme')
                end
           end
           time = time + numFrames*10e-3;
        end
        release(SDR);
    case 'BladeRF'
        if size(txWaveform, 2) == 1
            %% Send using BladeRF
            fprintf(' using Nuand BladeRF\n');
            SDRTx = bladeRF();
            SDR_tx_init(SDRTx, SDRv, txInfo);
            x = input('Introduce transmiting time in seconds\n');
            SDRTx.tx.start();
            time = tic;
            while toc(time) < x
                SDRTx.transmit(txWaveform);
            end
            SDRTx.tx.stop();
            clear SDRTx;
        else
            error('BladeRF: number of transmitter antennas can only be 1');
        end
    otherwise
        error('The radio selected is not a valid radio. Change the value of params.SDR.radio in setParams.m');
end
fprintf('End of transmission\n');
%clear time x samplesPerFrame numFrames eNodeB;