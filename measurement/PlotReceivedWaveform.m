function PlotReceivedWaveform(SamplingRate,waveform)

    % Create time series for x axis
    t=(0:length(waveform)-1)/SamplingRate;
    
    % Plot the absolute value of the waveform
    plot(t,abs(waveform));

    % Add plot label and set axis ranges
    xlabel('Time (s)');
    ylabel('Absolute value');    
    title('Absolute value of received waveform');    
    axis([t(1) t(end) 0 max(abs(waveform))*1.1]);
    
end