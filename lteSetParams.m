function [enb, PDSCH, MCS1, params, SDRv]=lteSetParams(params, subframeNr)

%% Instrument parameters
params.fc = '1 GHz'; %Hz, KHz, MHz or GHz
params.power = '-10'; %dBm

%% Test
params.image = [cd, '\import\Sat.jpg']; 

%% Channel characteristics for simulation

% channel.ModelType = 'GMEDS';
% channel.DelayProfile = 'EVA';
% channel.DopplerFreq = 70;
% channel.MIMOCorrelation = 'Medium';
% channel.NRxAnts = params.NRxAnts;
% channel.InitTime = 0;
% channel.InitPhase = 'Random';
% channel.Seed = 17;
% channel.NormalizePathGains = 'On';
% channel.NormalizeTxAnts = 'On';
% channel.SamplingRate = params.Rs;
% channel.NTerms = 16;

%% This are the number of frames to send or simulate
params.numFrames=10;
params.SNR=45;
% Radio values
SDRv.CenterFrequency         = 1e9; %Between 70MHz and 4GHz
SDRv.RadioGain               = 80;  %Between 0 and 80
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define cell-wide parameters
% Number of downlink resource blocks
% The standard defines 6 possible choices: 6,15,25,50,75,100
enb.NDLRB = 15;

% Number of Cell-Specific Reference Signal Antenna Ports
% Can be 1, 2 or 4
enb.CellRefP = 1;

% Physical Cell ID
% A number between 0 and 503
enb.NCellID = 1;

% Cyclic prefix type
% 'Normal' or 'Extended'
enb.CyclicPrefix = 'Normal';

% Channel Format Indicator value: 1, 2, or 3
% Specifies the number of OFDM symbols occupied by the control channel
% If NDLRB<=10, the number is CFI+1
enb.CFI = 3;

% Value used in the computation of the number of PHICH groups
% 'Sixth','Half','One', or 'Two'
enb.Ng = 'Sixth';

% Duration of the PHICH
% 'Normal' or 'Extended'
enb.PHICHDuration = 'Normal';

% Subframe number between 0 and 9
% Parameter is unused in this configuration
% enb.NSubframe = 0;

% Duplex mode: 'FDD' or 'TDD'
% Not tested with TDD
enb.DuplexMode = 'FDD';

% Number of CSI-RS antenna ports, specified as either 1, 2, 4, or 8.
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRefP = 1;

% CSI-RS configuration index, specified as an integer between 0 and 19 (FDD).
% See table 6.10.5.2-1 of TS 36.211
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRSConfig = 0;

% I_CSI-RS subframe configuration, specified as an integer between 0 and 154.
% See table 6.10.5.3-1 of TS 36.211
% Can also be set to 'on' or 'off'
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.CSIRSPeriod = 0;

% Zero-power CSI configuration, specified as an integer between 0 and 154.
% Can also be set to 'off' or 'on'
% Only used when TxScheme is set to Port7-14
% Parameter is unused in this configuration
% enb.ZeroPowerCSIRSPeriod = 'off';


%% Define the PDSCH parameters
% Some of these values could change every subframe
% Defining them inside the subframe loop
% Subframe number between 0 and 9
enb.NSubframe = mod(subframeNr,10);
enb.NFrame = floor(subframeNr/10);

% Transmission scheme. Possible values are:
% 'Port0', 'TxDiversity', 'CDD', 'SpatialMux', 'MultiUser',
% 'Port5', 'Port7-8', 'Port8', and 'Port7-14'
PDSCH.TxScheme = 'Port0';%This if only one antenna%'TxDiversity';

% Modulation scheme for the PDSCH
% Can be 'QPSK','16QAM', or '64QAM'
PDSCH.Modulation = '64QAM';%'QPSK';

% Number of layers
% It can only be 1,2,3 or 4 and must be less than CellRefP except
% for Port7-14, when it can take any value from 1 to 8
PDSCH.NLayers = 1;

% Radio Network Temporary Indentifier.
% A 16-bit value that identifies the mobile in this cell
PDSCH.RNTI = 1;

% Redundancy Version Sequence
% Defines the sequence of redundancy versions to use for retransmissions
% Example: [0] for no reTx, [0 1 2] for 3 reTx w/ HARQ, [0 0] for chase
PDSCH.RVSeq = [0 1 2 3];

% Redundancy version
% A scalar value that must be one of the values in RVSeq
PDSCH.RV = 0;

% Physical Resource Block Set
% The set of physical resource blocks allocated to the PDSCH
% Must be a subset of 0:NDLRB-1
PDSCH.PRBSet = (0:5)';

% Precoder Matrix Indication. Scalar between 0 and 15
% Only used when TxScheme is set to SpatialMux or MultiUser
% Parameter is unused in this configuration
% PDSCH.PMISet = 0;

% Number of transmit antennas. Must be 1 or more. 
% Only used when TxScheme is set to Port5, Port7-8, Port8, or Port7-14
% Parameter is unused in this configuration
% PDSCH.NTxAnts = 1;

% Weight for beamforming of dimension NLayers-by-NTxAnts. 
% Only used when TxScheme is set to Port5, Port7-8, Port8, or Port7-14
% Parameter is unused in this configuration
% PDSCH.W = 1;

% Target code rate for the PDSCH. Value between 0 and 1
% The generated program selects the transport block size that yields
% an effective code rate closest the requested value
PDSCH.TargetCodeRate = 5.000000e-01;

% Coded transport block size in bits
% This value is computed from other parameters
% It is the number of bits that fit in the allocated resource blocks
[~,info] = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
% CodedTrBlkSize is added to the PDSCH structure for convenience
% It is actually never read by any LTE System Toolbox function
PDSCH.CodedTrBlkSize = info.G;
% Here: PDSCH.CodedTrBlkSize = 1392

% (Uncoded) Transport block size in bits
% A number of values are possible depending on the modulation scheme
% and the number of resource blocks used for the PDSCH. The value
% that yields a code rate closest to the target code rate is selected
% Determine possible uncoded transport block sizes based on the number of
% resource blocks allocated to the PDSCH and the modulation scheme

NrLayersCW1 = 1;
% Use the number of layers to compute the TBS
[PDSCH,MCS1] = ComputeUTBS(PDSCH,NrLayersCW1,1);

