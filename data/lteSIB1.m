function [ subframe, PRBSet ] = lteSIB1(enb, PDSCH, subframe)
% This function adds the SIB1 to the provided subframe. Based on lteRMCDL.m
% SIB - System Information Block
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

if ~isfield(enb.SIB,'Data')
    error('lte:error','The function call resulted in an error: Could not find a SIB structure field called Data.');
end

if ~isfield(enb.SIB,'DCIFormat')
    enb.SIB.DCIFormat = 'Format1A';
    lte.internal.defaultValueWarning('SIB.DCIFormat','Format1A');    
end

if ~any(strcmpi(enb.SIB.DCIFormat,{'Format1A' 'Format1C'}) )
    error('lte:error','The function call resulted in an error: DCIFormat in SIB structure should be one of {''Format1A'', ''Format1C''}.');
end

if ~isfield(enb.SIB,'AllocationType')
    enb.SIB.AllocationType = 0;
    lte.internal.defaultValueWarning('SIB.AllocationType','0');    
end

if ~any(enb.SIB.AllocationType == [0 1])
    error('lte:error','The function call resulted in an error: The SIB field AllocationType should take one of the following values {0, 1}');
end

if enb.SIB.AllocationType == 1 % distributed
    if ~isfield(enb.SIB,'Gap')
        error('lte:error','The function call resulted in an error: Could not find a SIB structure field called Gap.');
    end
end

if ~isfield(enb.SIB,'VRBStart')
    error('lte:error','The function call resulted in an error: Could not find a SIB structure field called VRBStart.');
end

if ~isfield(enb.SIB,'VRBLength')
    error('lte:error','The function call resulted in an error: Could not find a SIB structure field called VRBLength.');
end
  
% Create and populate PDSCH structure for SIB1
PDSCHsib1.RNTI=65535; % SI-RNTI, 36.213
if (enb.CellRefP==1)
    PDSCHsib1.TxScheme='Port0';
    PDSCHsib1.NLayers=1;
else
    PDSCHsib1.TxScheme='TxDiversity';
    PDSCHsib1.NLayers=enb.CellRefP;
end
PDSCHsib1.Modulation=PDSCH.Modulation;%'QPSK'; %as per 36.213 Section 7.1.7.1

% RV setup for SIB1 per TS 36.321 Section 5.3.1
SFN = enb.NFrame;
k = mod(floor(SFN/2),4);
RVK = mod(ceil(3/2*k),4);
PDSCHsib1.RV = RVK;

% Get TBS
sib1Length = length(enb.SIB.Data);

if (strcmpi(enb.SIB.DCIFormat,'Format1A'))
    % Check for N1APRB only for Format1A
    if ~isfield(enb.SIB,'N1APRB')
        enb.SIB.N1APRB = 2;
        tbSizes = lteTBS(enb.SIB.N1APRB,0:26);
        if sib1Length>max(tbSizes) 
            enb.SIB.N1APRB = 3;
        end
    end
    % N1APRB: 36.212 Section 5.3.3.1.3 
    N1APRB = enb.SIB.N1APRB;    
    if ~any(N1APRB == [2 3])
        error('lte:error','The function call resulted in an error: SIB1 N1APRB field should take one of the following values {2, 3}');
    end
    % Tables from 36.213 Section 7.1.7.2.1    
    tbSizes = lteTBS(N1APRB,0:26);    
else % Format 1C
    % From 36.213 Sect 7.1.7.2.3
    tbSizes = [40 56 72 120 136 144 176 208 224 256 280 296 328 336 392 488 552 600 632 696 776 840 904 1000 1064 1128 1224 1288 1384 1480 1608 1736];
end

% Find nearest allowed TBS length
if sib1Length>max(tbSizes) 
    error('lte:error',['The function call resulted in an error: SIB1 data too long, maximum allowed length is ' num2str(max(tbSizes)) ' bits.']);
else
    % Find closer allowed TBS length
    iTBS = find(tbSizes>=sib1Length,1)-1; %I_TBS is zero based
    tbSize = tbSizes(iTBS+1);
    % Pad with zeros
    paddedSib1Bits = enb.SIB.Data(:);
    paddedSib1Bits=[paddedSib1Bits; zeros(tbSize-sib1Length,1)];
end

% Populate dcistr structure.
dcistr.AllocationType = enb.SIB.AllocationType;  
dcistr.NDLRB = enb.NDLRB;
dcistr.ModCoding = iTBS; % for SIB: I_TBS = I_MCS as per 36.213 Section 7.1.7.2 and Section 7.1.7    
if (strcmpi(enb.SIB.DCIFormat,'Format1A'))
    dcistr.DCIFormat='Format1A';    
    dcistr.RV = PDSCHsib1.RV; % RV setup for SIB1 per TS 36.321 Section 5.3.1
    if N1APRB == 2  % 36.212, Section 5.3.3.1.3
        dcistr.TPCPUCCH = 0;
    else
        dcistr.TPCPUCCH = 1;
    end
else    
    dcistr.DCIFormat='Format1C';
    if dcistr.AllocationType ~= 1
        error('lte:error', 'The function call resulted in an error: The SIB field AllocationType can only take the value 1 (distributed) for DCIFormat Format1C');
    end    
end

% gap field
if enb.SIB.AllocationType % distributed
    if ~any(enb.SIB.Gap == [0 1])
        error('lte:error', 'The function call resulted in an error: The SIB field Gap must be 0 (gap1) or 1 (gap2)');
    end
    % As per TS 36.212, Section 5.3.3.1.3 (DCI Format1A), the Gap value is
    % signalled via "New data indicator" field if the DCI message Format1A
    % is scrambled by SI-RNTI.
    if(strcmpi(dcistr.DCIFormat,'Format1A'))
        dcistr.NewData = enb.SIB.Gap;
    else
        dcistr.Allocation.Gap = enb.SIB.Gap;
    end
end

% RIV calculation
dcistr.Allocation.RIV = calculateRIV(enb.NDLRB,enb.SIB,true);

% Calculate SIB PRBSet from DCI
% As mentioned, the Gap value is signalled via "New data indicator" field
% if the DCI message Format1A is scrambled by SI-RNTI (TS 36.212 Section
% 5.3.3.1.3 (DCI Format1A)). However,the lteDCIResoureceAllocation function
% always expects the Gap signalled in the "Allocation.Gap" field. Create a
% copy of dcistr to pass to lteDCIResoureceAllocation(). Set the
% "AllocationType.Gap" field to carry the Gap value. Note that the actual
% mapped DCI message is correctly carrying the Gap value within the "New
% data indicator" field (structure dcistr).
tmpdcistr = dcistr;
if enb.SIB.AllocationType % distributed
    if(strcmpi(dcistr.DCIFormat,'Format1A'))
        tmpdcistr.Allocation.Gap = enb.SIB.Gap;
    end
end
PRBSet = lteDCIResourceAllocation(enb,tmpdcistr);

% SIB1 DL-SCH/PDSCH transmission
PDSCHsib1.PRBSet = PRBSet;

% SIB1 PDSCH indices
[sib1Indices, sibPDSCHInfo] = ltePDSCHIndices(enb,PDSCHsib1,PDSCHsib1.PRBSet);

% Channel code SIB1 bits
codedSib1Bits = lteDLSCH(enb,PDSCHsib1,sibPDSCHInfo.G,paddedSib1Bits);

% SIB1 PDSCH symbols, map to grid
pdschSymbols = ltePDSCH(enb,PDSCHsib1,codedSib1Bits); 
subframe(sib1Indices) = pdschSymbols;

% Add PDCCH
pdcchDims = ltePDCCHInfo(enb);                        
pdcchBits = -1*ones(1,pdcchDims.MTot);
pdcchConfig.NDLRB = enb.NDLRB;
pdcchConfig.PDCCHFormat = 2;
candidates = ltePDCCHSpace(enb,pdcchConfig,{'bits','1based'});

pdcchIndices = ltePDCCHIndices(enb);
pdcchConfig.RNTI = PDSCHsib1.RNTI;

[~,dciBits] = lteDCI(enb,dcistr);
codedDciBits = lteDCIEncode(pdcchConfig,dciBits);
pdcchBits (candidates(1,1) : candidates(1,2)) = codedDciBits;
pdcchSymbols = ltePDCCH(enb, pdcchBits);
% Assign PDCCH symbols to the subframe grid, but only where they are
% non-zero, to avoid overwriting any reference PDSCH DCI that might be
% present
subframe(pdcchIndices(abs(pdcchSymbols)~=0)) = pdcchSymbols(abs(pdcchSymbols)~=0);
end

% Calculates the RIV based on TS 36.213 Section 7.1.6.3
function RIV = calculateRIV(nRB, dciConfig, isSIB) 
%   Calculates the RIV based on TS 36.213 Section 7.1.6.3
%   Parameters:
%       - nRB: is the bandwidth in resource blocks
%       - dciConfig: SIB/DCI structure, the following fields are required:
%           - AllocationType (0: localized; 1 distributed)
%           - DCIFormat (Format1A, format1C)
%           - VRBStart
%           - VRBLength
%           - Gap (0: gap1; 1: gap2)
%       - isSIB: Flag to indicate SIB transmission where a SIB specific
%                error is thrown for incorrect configuration

    VRBStart = dciConfig.VRBStart;
    VRBLength = dciConfig.VRBLength;
    dciFormat = dciConfig.DCIFormat;
    allocationType = dciConfig.AllocationType;
    
    RIV = [];
    
    % Determine Nvrb
    if(allocationType == 1) % distributed
        % According to 36.211 Section 6.2.3.2
        gap = dciConfig.Gap;
        Nvrb = distributedNvrb(nRB,gap);          
    elseif(allocationType == 0) % localised
        % According to 36.211 Section 6.2.3.1
        Nvrb = nRB;
    end
    
    if(any(strcmpi(dciFormat, {'Format1A','Format1B','Format1D'})))        
        % From 36.213 Section 7.1.6.3
        if (VRBStart<0) || (VRBStart>(Nvrb-1))
            error('lte:error',['The function call resulted in an error: The SIB VRBStart parameter should be in the range [0, ' num2str(Nvrb-1) '] for the provided set of parameters'])
        end
        if (VRBLength<=(Nvrb-VRBStart) && VRBLength>=1)
            if((VRBLength-1)<= floor(nRB/2))
                RIV = nRB*(VRBLength-1) + VRBStart;
            else
                RIV = nRB*(nRB-VRBLength+1) + (nRB-1-VRBStart);
            end
        else
            if isSIB
                % If SIB creation, return error
                error('lte:error',['The function call resulted in an error: The SIB VRBLength parameter should be in the range [1, ' num2str(Nvrb-VRBStart) '] for the provided set of parameters'])
            else
                % If DCI creation, return empty RIV
                return;
            end    
        end
    elseif(strcmpi(dciFormat, 'Format1C'))        
        % Set Nstep: 36.213 Table 7.1.6.3-1
        if (nRB>5 && nRB<50)
            Nstep = 2;
        elseif(nRB>49 && nRB<111)
            Nstep = 4;
        end

        % From 36.213 Section 7.1.6.3
        % VRBStart valid values for Format1C
        VRBStartUpperLimit = (floor(Nvrb/Nstep)-1)*Nstep;
        if (VRBStart<0) || ( VRBStart>VRBStartUpperLimit ) || mod(VRBStart,Nstep)~=0
            VRBStartValidSet = 0:Nstep:VRBStartUpperLimit; % valid set of values for VRBStart for Format1C
            error('lte:error',['The function call resulted in an error: The SIB VRBStart parameter should be one of {' num2str(VRBStartValidSet) '} for the provided set of parameters'])
        end

        % Lcrb valid values for Format1C
        % Lcrb upper limits:
        %    - According to 36.213 Section 7.1.6.3 Lcrb <= floor(Nvrb/Nstep)*Nstep
        %    - However VRBLength_prime <= Nvrb_prime - VRBStart_prime
        % Considering the definitions od VRBLength_prime, Nvrb_prime and
        % VRBStart_prime it follows that:
        %    VRBLength <= Nstep*(Nvrb_prime - VRBStart_prime) = floor(Nvrb/Nstep)*Nstep - VRBStart
        LcrbUpperLimit = floor(Nvrb/Nstep)*Nstep - VRBStart;
        if (VRBLength<Nstep) || (VRBLength>LcrbUpperLimit) || (mod(VRBLength,Nstep)~=0)
            VRBLengthValidSet = Nstep:Nstep:LcrbUpperLimit; % valid set of values for VRBLength for Format1C           
            error('lte:error',['The function call resulted in an error: The SIB VRBLength parameter should be one of {' num2str(VRBLengthValidSet) '} for the provided set of parameters'])
        end
        
        VRBLength_prime = VRBLength/Nstep;
        VRBStart_prime = VRBStart/Nstep;
        Nvrb_prime = floor(Nvrb/Nstep);
        
        if(VRBLength_prime<=(Nvrb_prime-VRBStart_prime))
            if((VRBLength_prime-1) <= floor(Nvrb_prime/2))
                RIV = Nvrb_prime*(VRBLength_prime - 1) + VRBStart_prime;
            else
                RIV = Nvrb_prime*(Nvrb_prime - VRBLength_prime + 1) + (Nvrb_prime - 1 - VRBStart_prime);
            end
%         else % Condition not needed as already checked with the range of VRBLength
%             error('lte:error',['The SIB Lcrb parameter should be <=' num2str(Nvrb_prime*Nstep - VRBStart) ' for the provided bandwidth'])
        end
    end
end
