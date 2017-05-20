function [txWaveform, txCW, resourceGrids]= lteTx(txInfo, enb, subframes, params)
for n=1:txInfo.TotSubframes
    % Set enb to actual frame and subframe
    [enb, PDSCH, ~]=setParams(params, n);
    %% Generate empty OFDM subframe grid
    subframe = lteDLResourceGrid(enb);
    %% Add PDCCH - Physical Downlink Control CHannel
%     % DCI - Downlink Control Information format
%     % Can be 'Format0' ,'Format1', 'Format1A', 'Format1B', 'Format1C',
%     % 'Format1D', 'Format2', 'Format2A', 'Format2B', 'Format2C',
%     % 'Format3', 'Format3A', or 'Format4'
%     dciConfig.DCIFormat = 'Format1';
% 
%     % Build the DCI structure with relevant information
%     % Bitmap for resource allocation as per TS36.213 section 7.1.6.1
%     % for resource allocation type 0
%     dciConfig.Allocation.Bitmap = '11000000000000000';
%     % Modulation and coding scheme & redundancy version
%     dciConfig.ModCoding = MCS1; 
%     dciConfig.RV = PDSCH.RV; 
    % Adding SIB1            
    SFN = enb.NFrame;
    % If SIB substructure is present and for the right subframes
    if (isfield(enb,'SIB')) && (mod(n,10) == 5) && (mod(SFN,2)==0)

        % If Enable field not specified default to On
        if ~isfield(enb.SIB,'Enable')
            enb.SIB.Enable = 'On';
            lte.internal.defaultValueWarning('SIB.Enable','On');
        end
        if any(strcmpi(enb.SIB.Enable,{'On','Enable'})) 
            [subframe, ~] = lteSIB1(enb, txInfo, subframe);
        end
    else
        % DCI - Downlink Control Information message
        [~, dciMessageBits] = lteDCI(enb, enb.DCI);

        % 16-bit value number
        pdcchConfig.RNTI = PDSCH.RNTI;
        % PDCCH format: 0,1,2 or 3
        % Defines the aggregation level in CCEs (Control Channel Elements)
        % The level is 2^PDCCHFormat, respectively 1,2,4 and 8
        pdcchConfig.PDCCHFormat = 2;

        % Performing DCI message bits coding to form coded DCI bits
        codedDciBits = lteDCIEncode(pdcchConfig, dciMessageBits);
        % Get the total resources for PDCCH
        pdcchInfo = ltePDCCHInfo(enb);
        % Initialized with -1
        pdcchBits = -1*ones(pdcchInfo.MTot, 1);
        % Compute all candidates for placement
        candidates = ltePDCCHSpace(enb, pdcchConfig, {'bits','1based'});
        % Pick the first candidate in the list
        pdcchBits( candidates(1, 1) : candidates(1, 2) ) = codedDciBits;
        % Modulate the PDCCH and compute the indices for it
        pdcchSymbols = ltePDCCH(enb, pdcchBits);
        pdcchIndices = ltePDCCHIndices(enb, {'1based'});
        % Map PDCCH to the subframe grid, but only where they are non-zero,
        % to avoid overwriting any reference PDSCH DCI that might be present
        subframe(pdcchIndices(abs(pdcchSymbols)~=0)) = pdcchSymbols(abs(pdcchSymbols)~=0);
%         subframe(pdcchIndices) = pdcchSymbols;
    end
    %% Add Cell-Specific Reference Signals
    % Generate the indices
    cellRSIndices = lteCellRSIndices(enb);
    % Value of the symbols
    cellRSSymbols = lteCellRS(enb);
    subframe(cellRSIndices) = cellRSSymbols;

    %% Add Primary and Secondary Synchronization Signals
    pssSymbols = ltePSS(enb);
    sssSymbols = lteSSS(enb);
    pssInd = ltePSSIndices(enb);
    sssInd = lteSSSIndices(enb);
    % Map synchronization signals to the grid
    subframe(pssInd) = pssSymbols;
    subframe(sssInd) = sssSymbols;
    
    %% Add BCH - Broadcast CHannel
    % If first subframe in a frame
    % Add MIB - Master Information Block to PBCH - Physical Broadcast
    % CHannel
    if mod(enb.NSubframe,10) == 0
        % Every 4 frames (40ms), MIB changes. The toolbox knows this by
        % using enb.NFrame
        mib = lteMIB(enb);
        pbchIndices = ltePBCHIndices(enb);
        QuarterLength = numel(pbchIndices)/enb.CellRefP; % 240 for Normal prefix, 216 for Extended
        bchcoded = lteBCH(enb,mib);
        pbchSymbols = ltePBCH(enb,bchcoded);
        startBCH = mod(enb.NFrame,4)*QuarterLength;
        pbchSymbolsThisFrame = pbchSymbols(startBCH+(1:QuarterLength),:);
        subframe(pbchIndices) = pbchSymbolsThisFrame;
    end

    %% Add the CFI - Control Format Indicator
    cfiBits = lteCFI(enb);
    % Encode CFI to to PCFICH - Physical Control Format Indicator CHannel
    pcfichSymbols = ltePCFICH(enb, cfiBits);
    pcfichIndices = ltePCFICHIndices(enb);
    % Map CFI to the grid
    subframe(pcfichIndices) = pcfichSymbols;

    %% Add the PHICH - Physical Hybrid-ARQ Indicator CHannel
    HIValue = [0 0 1]; % Map an ACK to the first sequence of the first group
    phichSymbols = ltePHICH(enb,HIValue);
    phichIndices = ltePHICHIndices(enb);
    subframe(phichIndices) = phichSymbols;

    %% Add the PDSCH - Physical Downlink Shared CHannel
    % Encode the transport block
    codedTrBlock = lteDLSCH(enb, PDSCH, PDSCH.CodedTrBlkSize, subframes(:,n));
    % Modulate the transport block
    pdschSymbols = ltePDSCH(enb, PDSCH, codedTrBlock);
    txCW=pdschSymbols;
    % Subframe resource allocation
    pdschIndices = ltePDSCHIndices(enb, PDSCH, PDSCH.PRBSet);
    subframe(pdschIndices) = pdschSymbols;
    
    %% Add CSI-RS Signals
    if (~isempty(pdschSymbols) && any(strcmpi(PDSCH.TxScheme,'Port7-14')))
        csiRsIndices=lteCSIRSIndices(enb);
        csiRsSymbols=lteCSIRS(enb);
        % Remove the zero power CSI-RS symbols and indices as the
        % Zero power CSIRS symbols are always 4 ports, we only need
        % to transmit CSIRefP ports, but ensure that all RE
        % locations corresponding to zero power CSIRS symbols in
        % all ports (4) are zeroed.
        csiRsIndices(csiRsSymbols==0)=[];
        csiRsSymbols(csiRsSymbols==0)=[];
        % Extract the RE indices corresponding to CSIRefP for all
        % used and unused CSI-RS locations
        csiRsIndicesall=lteCSIRSIndices(enb,'rs+unused');
        [~,reind] = lteExtractResources(csiRsIndicesall,subframe);
        % Add zeros for all CSIRS RE positions in the active
        % CSIRefP ports
        subframe(reind) = 0;
        % Map the CSI-RS symbols onto the resource elements
        subframe(csiRsIndices)=csiRsSymbols;
    end
    %% Concatenate this subframe resource grid to the total resource grid
    if n == 1
        resourceGrids = subframe;
    else
        resourceGrids = [resourceGrids subframe]; %#ok<AGROW>
    end
end
%% Modulation of final signal
% lteOFDMModulate - Signal is OFDM with Cyclic Prefix (LTE)
% lteFOFDMTx      - Signal is Filtered OFDM (5G candidate)
% lteUFMCTx       - Signal is Universal Filtered Multicarries Modulation 
%                   (5G candidate)
% 
switch params.WaveMod
    case 'OFDM'
        txWaveform = lteOFDMModulate(enb, resourceGrids);
    end