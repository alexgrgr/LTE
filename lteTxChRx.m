function [txWaveform, rxWaveform, rxBits, txCW, rxCW ]=...
    lteTxChRx(txBits, enb, PDSCH, MCS1, channel, SNRdB)
%% Apply transmitter operations
[txWaveform, txCW]= lteTx(enb, PDSCH, MCS1, txBits);
%% Apply Channel modeling
rxWaveform= lteCh(txWaveform,enb,channel,SNRdB);
%% Apply receiver operations
[rxBits, rxCW]= lteRx(rxWaveform, enb, PDSCH);