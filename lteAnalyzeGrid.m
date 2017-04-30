%% Analysis
% Plot the received grid before and after equalization
subplot(2,1,1)
surf(1:size(rxGrid,2),1:size(rxGrid,1),20*log10(abs(rxGrid(:,:,1))));
title('Received resource grid');
ylabel('Subcarrier');
xlabel('Symbol');
zlabel('absolute value (dB)');
axis([1 14 1 enb.NDLRB*12 -40 10]);

subplot(2,1,2)
surf(1:size(eqGrid,2),1:size(eqGrid,1),20*log10(abs(eqGrid(:,:,1))));
title('Equalized resource grid');
ylabel('Subcarrier');
xlabel('Symbol');
zlabel('absolute value (dB)');
axis([1 14 1 enb.NDLRB*12 -40 10]);