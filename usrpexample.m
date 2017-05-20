%% LTE SIB1 Transmission over Two Antennas
% This example uses both channels of USRP(R) B210, X300 or X310 to transmit
% an LTE downlink signal that requires two antennas. The signal is generated
% by the LTE System Toolbox(TM) and random bits are inserted into the SIB1 field,
% the first of the System Information Blocks. The accompanying example 
% <matlab:edit('sdruLTE2x2SIB1Rx.m') sdruLTE2x2SIB1Rx.m> receives this
% signal with two antennas, recovers the SIB1 data, and checks the CRC.
%
% This example uses the SDRu Transmitter System object(TM). The ChannelMapping
% property of the object is set to [1 2] to enable use of both channels.
% The step method takes a two-column matrix in which the first column is
% the signal for 'RF A' of the radio and the second column is the
% signal for 'RF B' of the radio.
%
% After starting this example, please run <matlab:edit('sdruLTE2x2SIB1Rx.m') sdruLTE2x2SIB1Rx.m>
% in a new MATLAB session. In Windows, if two B210 radios are used for these
% examples, each radio must be connected to a separate computer.
%
% Please refer to the Setup and Configuration section of <matlab:sdrudoc
% Documentation for USRP(R) Radio> for details on configuring your host
% computer to work with the SDRu Transmitter System object.
%
% Copyright 2015-2016 The MathWorks, Inc.

%% Generate LTE Signal

% Check for presence of LTE System Toolbox
if isempty(ver('lte'))
    error(message('sdru:examples:NeedLST'));
end

% Generate LTE signal
rmc = lteRMCDL('R.4');     % Base RMC configuration
rmc.CellRefP = 1;           % 2 transmit antennas 
rmc.PDSCH.NLayers = 1;      % 2 layers 
rmc.NCellID = 64;           % Cell identity
rmc.NFrame = 100;           % Initial frame number
rmc.TotSubframes = 8*10;    % Generate 8 frames. 10 subframes per frame
rmc.OCNGPDSCHEnable = 'On'; % Add noise to unallocated PDSCH resource elements
rmc.PDSCH.RNTI = 61;
rmc.SIB.Enable = 'On';
rmc.SIB.DCIFormat = 'Format1A';
rmc.SIB.AllocationType = 0;
rmc.SIB.VRBStart = 0;
rmc.SIB.VRBLength = 6;
rmc.SIB.Gap = 0;
rmc.SIB.Data = randi([0 1],144,1); % Use random bits in SIB data field. This is not a valid SIB message
trData = [1;0;0;1];
[eNodeBOutput,txGrid,rmc] = lteRMCDLTool(rmc,trData);

%% Plot Power Spectrum of Two-Channel LTE Signal

spectrumAnalyzer = dsp.SpectrumAnalyzer;
spectrumAnalyzer.SampleRate = rmc.SamplingRate;  % 1.92e6 MHz for 'R.12'
spectrumAnalyzer.Title = 'Power Spectrum of Two-Channel LTE Signal';
spectrumAnalyzer.ShowLegend = true;
step(spectrumAnalyzer, eNodeBOutput);
release(spectrumAnalyzer);

%% Connect to Radio

radioFound = false;
radiolist = findsdru;
for i = 1:length(radiolist)
  if strcmp(radiolist(i).Status, 'Success')
    if strcmp(radiolist(i).Platform, 'B210')
        radio = comm.SDRuTransmitter('Platform','B210', ...
                 'SerialNum', radiolist(i).SerialNum);
        radio.MasterClockRate = 1.92e6 * 4; % Need to exceed 5 MHz minimum
        radio.InterpolationFactor = 4;      % Sampling rate is 1.92 MHz
        radioFound = true;
        break;
    end
    if (strcmp(radiolist(i).Platform, 'X300') || ...
        strcmp(radiolist(i).Platform, 'X310'))
        radio = comm.SDRuTransmitter('Platform',radiolist(i).Platform, ...
                 'IPAddress', radiolist(i).IPAddress);
        radio.MasterClockRate = 184.32e6;
        radio.InterpolationFactor = 96;     % Sampling rate is 1.92 MHz
        radioFound = true;
    end
  end
end

if ~radioFound
    error(message('sdru:examples:NeedMIMORadio'));
end

radio.ChannelMapping = 1;%[1 2];     % Use both TX channels
radio.CenterFrequency = 1e9;
radio.Gain = 25;
radio.UnderrunOutputPort = true;

radio

%% Send Signal over Two Antennas

% Scale signal to make maximum magnitude equal to 1
eNodeBOutput = eNodeBOutput/max(abs(eNodeBOutput(:)));

% Reshape signal as a 3D array to simplify the for loop below
% Each call to step method of the object will use a two-column matrix
samplesPerFrame = 10e-3*rmc.SamplingRate;      % LTE frames are 10 ms long
numFrames = length(eNodeBOutput)/samplesPerFrame;
txFrame = permute(reshape(permute(eNodeBOutput,[1 3 2]), ...
                  samplesPerFrame,numFrames,rmc.CellRefP),[1 3 2]);

disp('Starting transmission');
disp('Please run sdruLTE2x2SIB1Rx.m in a new MATLAB session');

currentTime = 0;
while currentTime < 300                        % Run for 5 minutes
    for n = 1:numFrames
        % Call step method to send a two-column matrix
        % First column for TX channel 1. Second column for TX channel 2
        bufferUnderflow = step(radio,txFrame(:,:,n));
        if bufferUnderflow~=0
            warning('sdru:examples:DroppedSamples','Dropped samples')
        end
    end
    currentTime = currentTime+numFrames*10e-3; % One frame is 10 ms
end
release(radio);
disp('Transmission finished')

%% Tips for Maximizing Performance
% 
% * Run this example and <matlab:edit('sdruLTE2x2SIB1Rx.m') sdruLTE2x2SIB1Rx.m> on two computers
% * Double InterpolationFactor in this example and DecimationFactor in <matlab:edit('sdruLTE2x2SIB1Rx.m') sdruLTE2x2SIB1Rx.m>
% * Start MATLAB in -nodesktop mode before running this example
% * If you are using one computer with two B210 radios, do not connect them to adjacent USB ports

displayEndOfDemoMessage(mfilename)

%% Copyright Notice
% Universal Software Radio Peripheral(R) and USRP(R) are trademarks of
% National Instruments Corp.
