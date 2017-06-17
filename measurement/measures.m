function ber = measures (enb, PDSCH, params, txInfo)
% Set up initial parameters.
EbNomin = 0; EbNomax = 17; % EbNo range, in dB
numerrmin = 100; % Compute BER only after 19 errors occur.
EbNovec = EbNomin:1:EbNomax; % Vector of EbNo values
numEbNos = length(EbNovec); % Number of EbNo values
% Preallocate space for certain data.
ber = zeros(1,numEbNos); % final BER values
berVec = zeros(3,numEbNos); % Updated BER values
intv = cell(1,numEbNos); % Cell array of confidence intervals
%% Loop over the vector of EbNo values.
for i = 1:numEbNos
    txInfo.SNR = EbNovec(i); % Because of binary modulation
    % Simulate until numerrmin errors occur.
    while (berVec(2,i)) < numerrmin
        [txBits, rxBits] = berLTE (enb, PDSCH, params, txInfo);
        berVec(:,i) = step(comm.ErrorRate, txBits, double (rxBits));
    end
    % Error rate and 98% confidence interval for this EbNo value
    [ber(i), intv1] = berconfint(berVec(2,i),berVec(3,i)-1,.98);
    intv{i} = intv1; % Store in cell array for later use.
    disp(['SNR = ' num2str(txInfo.SNR) ' dB, ' num2str(berVec(2,i)) ...
        ' errores, BER = ' num2str(berVec(1, i))])
end
% Use BERFIT to plot the best fitted curve,
% interpolating to get a smooth plot.
figure;
fitEbNo = EbNomin:0.25:EbNomax; % Interpolation values
berfit(EbNovec,berVec(1,:),fitEbNo,[],'exp');
% Also plot confidence intervals.
hold on;
for i=1:numEbNos
   semilogy([EbNovec(i) EbNovec(i)],intv{i},'g-+');
end
hold off;
% PDSCH.TrBlkSize = tempTrBlkSize;


end