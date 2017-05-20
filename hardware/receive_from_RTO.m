function u = receive_from_RTO(sIPAddress, nSampleRate, nChannelNo, nNofSamples,...
    nCarrierFrequency) 
    %***************************************************************
    % This function configures the RTO via TCPIP and queries I/Q data.
    %
    %   Input Parameters
    %       sRTO_hostname:       host name of the connected RTO
    %       nChannelNo:          RTO Channel to be used
    %       nSampleRate:         Sampling Rate in Samples / Second
    %       nNofSamples:         Number of IQ samples to be recorded
    %
    %   Optional Input Parameters
    %       nCarrierFrequency:  Carrier Frequency for the measurement in Hz
    %       sSideband:          for real inputs defines the frequency position
    %                           of the RF spectrum in the input signal.
    %                           For complex inputs defines the sideband and
    %                           frequency position of the complex modulated
    %                           input signal in IF range. The position is 
    %                           important for correct down-conversion and filtering                            
    %       nRelBW:             relative bandwidth factor
    %   
    %   Return Values
    %       u:                  IQ samples as complex matlab vector.
    %
    % Terms of Use: Rohde & Schwarz products and services are supplied to
    % customers subject to certain contractual terms and conditions. In
    % addition, there are some requirements that apply especially to certain
    % products, customers or circumstances.
    % see http://www.termsofuse.rohde-schwarz.com/
    %
    % Copyright: (c) 2012 Rohde & Schwarz GmbH & CO KG. All rights reserved.
    %                Muehldorfstr. 15, D-81671 Munich, Germany
    %
    % PROJECT:       Matlab tools.
    %
    % LANGUAGE:      Matlab Interpreter.
    %
    % AUTHORS:       Dr. Mathias Hellwig
    %                Rafael Ruiz
    %
    % PREMISES:      None.
    %
    % REMARKS:       None.
    %
    % HISTORY:       $Log: $
    %
    % ****************************************************************************
    %nCarrierFrequency = 806e6;
    % oversampling with a factor of 80 given a symbol rate of 500ksym/s
    %nSampleRate = 15360000;
    % number of samples
    %nNofSamples = 800000;
    % channel connected to the IQ signal source
    %nChannelNo = 1;
    % name of the RTO to access remotely via network
    sRTO_hostname = 'RTO-2044';
    %sIPAddress = resolvehost(sRTO_hostname, 'address');
    % Create a VISA connection to the specified IP address
    RTO = visa('ni', ['TCPIP::' sIPAddress ]);
    % increase the buffer size to, e.g., transport IQ data
    RTO.InputBufferSize = 20e6;
    % Open the instrument connection
    fopen(RTO);
    %Activate View-Mode in Remote Mode
    fprintf(RTO,'SYST:DISP:UPD ON');
    %% ----- Configure the RTO -----
    % Preset the RTO and wait till action is finished
    fprintf(RTO,'*RST; *OPC?');
    [~] = fscanf(RTO);
    % Set Coupling to 50 Ohm
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':COUP DC']);
    % Perform Autoleveling,
    %this might take some time so synchonization is adviced
    fprintf(RTO, ' AUToscale; *OPC?');
    [~] = fscanf(RTO);
    sInputType = 'REAL';
    sInputMode = 'RFIF';
    sSideband = 'NORMal';
    nRelBW = 0.6;
    % Activate IQ Mode
    fprintf(RTO,'IQ:STATe ON; *OPC?');
    [~] = fscanf(RTO);
    % Single Sweep Mode
    fprintf(RTO,'STOP');
    %Set the input signal, input mode and sideband
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':IQ:INPType ' sInputType]);
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':IQ:INPMode ' sInputMode]);
    % Use Normal Sideband
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':IQ:SBRF ' sSideband]);
    % Carrier Frequency or Center Frequency
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':IQ:CFRequency ' ...
    num2str(nCarrierFrequency)]);
    % Set the correct sampling rate
    fprintf(RTO, ['IQ:SRATe ' num2str(nSampleRate)]);
    % Set the relative Bandwidth
    fprintf(RTO, ['IQ:RBWidth ' num2str(nRelBW)]);
    % Record Length to be used
    fprintf(RTO, ['IQ:RLEN ' num2str(nNofSamples)]);
    %% format of the transmission [ASC/UINT/REAL]
    sDataFormat = 'REAL,32';
    sDataFormat = sprintf('FORM %s', sDataFormat);
    sBinaryFormatString = 'float';
    nSizeType = 4;
    fprintf(RTO, sDataFormat);
    %% ----- Perform Single Sweep -----
    % Perform a Sweep, and sync via '*OPC?' with the following read
    fprintf(RTO, 'RUNSingle; *OPC?');
    [~] = fscanf(RTO);
    %% ----- Query the IQ Data -----
    % data comes in #NLLLLFFFFffff …
    % with N length indicator
    % LLLL number of samples
    % FFFF/ffff 4 byte value according to IEEE 754
    % Capture the IQ Data from the corresponding channel
    fprintf(RTO, ['CHAN' int2str(nChannelNo) ':IQ:DATA:VALues?']);
    % check the return beginning with a hash '#'
    sStartIndicator = fread(RTO,1,'char');
    if sStartIndicator ~= '#'; fprintf('ooops!\n'); end;
    % check the length of the length field in units
    nLengthOfLengthfield = fread(RTO,1,'char');
    nLengthOfLengthfield = str2double(char(nLengthOfLengthfield));
    % check the length of the data record
    nBlockLength = fread(RTO, nLengthOfLengthfield ,'char');
    nBlockLength = str2double(char(nBlockLength)) / nSizeType;
    % to make this work, the endianess endian must be considered!
    % the RTO supports litte endian byte order
    u = fread(RTO, nBlockLength, sBinaryFormatString);
    [~] = fread(RTO,1,'char');
    u = u(1:2:end) + 1i*u(2:2:end);
%     %% ----- Plot I/Q data -----
%     % normalize to mean power of 1
%     nMeanMagnitude = sqrt(mean(real(u).^2 + imag(u).^2));
%     u = u / nMeanMagnitude;
%     plot(u);
%     % second plot
%     nOverSampling = nSampleRate / 500000; % symbol rate -- 500 ksym/s
%     nSync = 60; % visually determined
%     meanPhase = mean(angle(u(nSync:nOverSampling:end)));
%     for phase=1:nOverSampling;
%     plot((u((1+phase):nOverSampling:end)*exp(-1i*meanPhase)), '.');
%     pause(0.5);
%     end
    fclose(RTO);
    delete(RTO);
return;