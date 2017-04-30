function ber = meassures (enb, PDSCH, MCS1, channel)
% Set up initial parameters.
EbNomin = 0; EbNomax = 17; % EbNo range, in dB
numerrmin = 100; % Compute BER only after 19 errors occur.
EbNovec = EbNomin:1:EbNomax; % Vector of EbNo values
numEbNos = length(EbNovec); % Number of EbNo values
% Preallocate space for certain data.
ber = zeros(1,numEbNos); % final BER values
berVec = zeros(3,numEbNos); % Updated BER values
intv = cell(1,numEbNos); % Cell array of confidence intervals
% tempTrBlkSize = PDSCH.TrBlkSize;
% PDSCH.TrBlkSize = 10000;%Very few because it is very slow
TrBlkSize = PDSCH.TrBlkSize; 
% Modulation scheme for the PDSCH
% Can be 'QPSK','16QAM', or '64QAM'
PDSCH.Modulation = '64QAM';%'QPSK';
% Loop over the vector of EbNo values.
for jj = 1:numEbNos
    EbNo = EbNovec(jj);
    SNR = EbNo; % Because of binary modulation
    % Simulate until numerrmin errors occur.
    while (berVec(2,jj)) < numerrmin
        %% Generate input bits for every SNR
        txBits = randi([0, 1], TrBlkSize, 1);
        %% Run Transceiver (Transmiter-Channel-Receiver)
        [~, ~, rxBits, ~, ~] = ...
            lteTxChRx(txBits, enb, PDSCH, MCS1, channel, SNR);
        berVec(:,jj) = step(comm.ErrorRate, txBits(2:end), double (rxBits(2:end)));
    end
    % Error rate and 98% confidence interval for this EbNo value
    [ber(jj), intv1] = berconfint(berVec(2,jj),berVec(3,jj)-1,.98);
    intv{jj} = intv1; % Store in cell array for later use.
    disp(['SNR = ' num2str(EbNo) ' dB, ' num2str(berVec(2,jj)) ...
        ' errores, BER = ' num2str(berVec(1, jj))])
end
% Use BERFIT to plot the best fitted curve,
% interpolating to get a smooth plot.
figure;
fitEbNo = EbNomin:0.25:EbNomax; % Interpolation values
berfit(EbNovec,berVec(1,:),fitEbNo,[],'exp');
% Also plot confidence intervals.
hold on;
for jj=1:numEbNos
   semilogy([EbNovec(jj) EbNovec(jj)],intv{jj},'g-+');
end
hold off;
% PDSCH.TrBlkSize = tempTrBlkSize;
end