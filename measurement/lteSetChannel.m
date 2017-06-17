function params = lteSetChannel(txInfo, PDSCH, params)
params.channel.NRxAnts = PDSCH.NLayers;
params.channel.SamplingRate = txInfo.SamplingRate;