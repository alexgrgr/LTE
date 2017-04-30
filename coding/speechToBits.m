function [txBitsAll, txpcm] = speechToBits(Fs, FrameSize, SecondsOfSpeech, Interactive)
DataType='int16';
numBitsPerSample = 8;
LawG711='Mu';
params = initializeSpeechCoding(LawG711);
if ~Interactive
    LiveAudioSource = dsp.AudioFileReader(...
        'Filename', 'speech_dft_8kHz.wav', 'PlayCount', 2, ...
        'OutputDataType', DataType,'SamplesPerFrame',FrameSize);
    fprintf(1,'\nUsing audio file: speech_dft_8kHz.wav\n');
else
    LiveAudioSource = dsp.AudioRecorder(...
        'NumChannels',1, 'SampleRate',Fs, ...
        'OutputDataType', DataType,'SamplesPerFrame',FrameSize);
    fprintf(1,'\nPlease Speak! \nRecording about (%d sec.) of your voice ...',...
        fix(SecondsOfSpeech));
end
TxAudioFile = dsp.AudioFileWriter(...
    'Filename', 'TxSpeech.wav', 'SampleRate', Fs);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numBitsPerFrame = FrameSize * numBitsPerSample;
numTotalSamples = SecondsOfSpeech * Fs;
numTotalFrames = ceil(numTotalSamples/FrameSize);
%%%%%%%%%%%%%%%%%%%%%%%%% Speech Encoding loop %%%%%%%%%%%%%%%
txBitsAll=zeros(numBitsPerFrame*numTotalFrames,1);
prev=0;
txpcm=[];
gain=2^(15-params.DR);
for index=1:numTotalFrames
    y=step(LiveAudioSource);
%     step(TxAudioFile, y);
    y1=(2^(params.DR-15))*y;
    % Speech encoding to G711
    txBits=speechEncode(y1, LawG711, params);
    pcm = speechDecode(txBits, LawG711, params);
    step(TxAudioFile, int16(gain*pcm));
    txpcm=[txpcm;pcm];
    txBitsAll(prev+(1:numBitsPerFrame)') = txBits;
    prev=prev+numBitsPerFrame;
end
fprintf(1,'File name = TxSpeech.wav \n\n');
release(LiveAudioSource);
release(TxAudioFile);
end