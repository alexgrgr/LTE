% Use this script to edit all variables that can be used with this program
function [enb, PDSCH, params] = setParams(params, subframeNr)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                SMBV100A Instrument parameters                   %%%%%
params.SMBV100A.fc = '1 GHz'; %Hz, KHz, MHz or GHz
params.SMBV100A.power = '-40'; %dBm
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                 RTO2044 Instrument parameters                   %%%%%
params.RTO2044.fc = 1e9;
params.RTO2044.SamplingRate = 15360000; % 15360000 for OFDM
params.RTO2044.IP = '138.100.50.99';
params.RTO2044.Channel = 1; % Oscilloscope Channel
params.RTO2044.Samples = 800000;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                 Software Defined Radios values                  %%%%%
params.SDR.Radio           = 'BladeRF'; % 'B210' or 'BladeRF'
params.SDR.CenterFrequency = 806e6; %Between 70MHz and 4GHz
params.SDR.RadioGain       = 20;  %Between 0 and 80
params.SDR.RxRadioGain     = 80;
params.SDR.RxOffset        = 0;% 585.9375; %RF Offset in Hz. Calculated receiving a tone. This one is for B210
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%                 Number of frames to generate                    %%%%%
params.numFrames=10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%             Channel characteristics for simulation              %%%%%
% Channel Models conditions
% b2 - Multipath-fading MIMO conditions as of 3GPP TS 36.104 Annex B.2
% b3 - High speed train conditions as of 3GPP TS 36.104 Annex B.3
% b4 - Moving propagation conditions as of 3GPP TS 36.104 Annex B.4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Common values
params.channel.condition = 'b2';
params.channel.ModelType = 'GMEDS';       % Rayleigh fading model type
params.channel.DelayProfile = 'EVA';      % Delay profile EVA, EVA or ETU
params.channel.DopplerFreq = 15;          % Maximum Doppler frequency, in Hz
params.channel.InitTime = 1;              % Fading process time offset, in seconds
params.channel.Seed = 17;                 % Random number generator seed
params.channel.NormalizePathGains = 'On'; % Model output normalization
params.channel.NormalizeTxAnts = 'On';    % Transmit antenna number normalization
params.channel.NTerms = 8;                % Number of oscillators used in fading path modeling

% Only for B2 ()
params.channel.InitPhase = 'Random';       % Phase initialization for the sinusoidal components of the model
params.channel.MIMOCorrelation = 'Medium'; %Correlation between UE and eNodeB antennas

% Only for B3 (High speed train conditions)
params.channel.Ds = 10;            %Train-to-eNodeB double initial distance, in meters
params.channel.Dmin = 2;           %eNodeB to railway track distance, in meters
params.channel.Velocity = 200;     % Train velocity, in kilometers per hour

% Only for B4 (Moving propagation conditions)
params.channel.MovingScenario = 'Scenario1'; % Moving channel scenario (3GPP)

% SNR for simulation purposes. AWGN will be applied
params.SNR=45;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%               Modulation of final signal options                %%%%%
% CPOFDM - Signal is OFDM with Cyclic Prefix (LTE)
%  FOFDM - Signal is Filtered OFDM (5G candidate)
%   UFMC - Signal is Universal Filtered Multicarries Modulation (5G candidate)
params.WaveMod = 'CPOFDM';   %'CPOFDM';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%                5G candidate modulations options                 %%%%%
%    fLen        - filter length in samples, for F-OFDM only
%    toneOffset  - tone offset in subcarriers, for F-OFDM only
%    slobeAtten  - sidelobe attenuation in dB, for UFMC only
%    Nrb_sc      - no. of subcarriers per resource block
%    Ndl_symb    - no. of OFDM symbols in a slot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enb.FiveG.FOFDM.FilterLenght = 513;
enb.FiveG.FOFDM.toneOffset   = 2.5;
enb.FiveG.FOFDM.Nrb_sc       = 12;
enb.FiveG.FOFDM.Ndl_symb     = 7;
enb.FiveG.UFMC.slobeAtten    = 75;
enb.FiveG.UFMC.Nrb_sc        = 12;
enb.FiveG.UFMC.Ndl_symb      = 7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%                   Define cell-wide parameters                   %%%%%
% Number of downlink resource blocks
% The standard defines 6 possible choices: 6,15,25,50,75,100
enb.NDLRB = 15;

% Number of Cell-Specific Reference Signal Antenna Ports
% Can be 1, 2 or 4
enb.CellRefP = 1;

% Physical Cell ID
% A number between 0 and 503
enb.NCellID = 12;

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

% Some of these values could change every subframe
% Defining them inside the subframe loop
% Subframe number between 0 and 9
enb.NSubframe = mod(subframeNr,10);
enb.NFrame = floor(subframeNr/10);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%               Define the PDSCH parameters                       %%%%%

% Transmission scheme. Possible values are:
% 'Port0', 'TxDiversity', 'CDD', 'SpatialMux', 'MultiUser',
% 'Port5', 'Port7-8', 'Port8', and 'Port7-14'
PDSCH.TxScheme = 'Port0';%This if only one antenna%'TxDiversity';

% Modulation scheme for the PDSCH
% Can be 'QPSK','16QAM', or '64QAM'
PDSCH.Modulation = 'QPSK';%'QPSK';

% Number of layers
% It can only be 1,2,3 or 4 and must be less than CellRefP except
% for Port7-14, when it can take any value from 1 to 8
PDSCH.NLayers = 1;

% Radio Network Temporary Indentifier.
% A 16-bit value that identifies the mobile in this cell. Value fixed to be
% SI-RNTI as on 3GPP 36.321 Table 7.1-1
PDSCH.RNTI = 65535; %0xFFFF  - SI-RNTI

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%                Define the DCI parameters                        %%%%%
%% DCI - Downlink Control Information format
% Can be 'Format0' ,'Format1', 'Format1A', 'Format1B', 'Format1C',
% 'Format1D', 'Format2', 'Format2A', 'Format2B', 'Format2C',
% 'Format3', 'Format3A', or 'Format4'
enb.DCI.DCIFormat = 'Format1A';
% Build the DCI structure with relevant information
% Bitmap for resource allocation as per TS36.213 section 7.1.6.1
% for resource allocation type 0
enb.DCI.Allocation.Type = 0;
enb.DCI.Allocation.Bitmap = '11000000000000000';
% Modulation and coding scheme & redundancy version
enb.DCI.ModCoding = MCS1; 
enb.DCI.RV = PDSCH.RV; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%               Define the SIB-1 parameters                       %%%%%
%% SIB - System Information Block
%  Data           - vector of bits to map to the SIB1
%  DCIFormat      - DCI format used, can be 'Format1A' and 'Format1C'
%  AllocationType - indocates whether the resources allocated are
%                   localized (0) or distributed (1)
%  VRBStart       - virtual RB allocation starting resource block
%  VRBLength      - length of virtually contiguously allocated resource block
%  N1APRB         - Number of physical resource blocks for Format1A
%  Gap            - Distributed allocation gap, can take the values 0 (gap1
%                   and 1 (gap2) Only required for distributed allocation 
%                   AllocationType = 1.
enb.SIB.Enable = 'On';
enb.SIB.Data = randi([0 1],144,1); % Use random bits in SIB data field. This is not a valid SIB message
enb.SIB.DCIFormat = enb.DCI.DCIFormat;
enb.SIB.AllocationType = 0;
enb.SIB.VRBStart = 0;
enb.SIB.VRBLength = 6;
%enb.SIB.N1APRB = ;
enb.SIB.Gap = 0;
