function txBitsAll = musicToBits(Fs, FrameSize, SecondsOfSpeech, Interactive)
DataType='double';
numBitsPerSample = 8;
LawG711='Mu';
params = initializeSpeechCoding(LawG711);
if ~Interactive
    [fileName,~,~] = uigetfile('*.m4a');
LiveAudioSource = dsp.AudioFileReader(...
    'Filename', fileName, 'PlayCount', 1, ...
    'OutputDataType', DataType ,'SamplesPerFrame',FrameSize);

    fprintf(1,'\nUsing audio file: %s\n', fileName);
else
    LiveAudioSource = dsp.AudioRecorder(...
        'NumChannels',1, 'SampleRate',Fs, ...
        'OutputDataType', DataType,'SamplesPerFrame',FrameSize);
    fprintf(1,'\nPlease Speak! \nRecording about (%d sec.) of your voice ...',...
        fix(SecondsOfSpeech));
end
TxAudioFile = dsp.AudioFileWriter(...
    'Filename', 'TxMusic.m4a', 'FileFormat', 'MPEG4', 'SampleRate', Fs);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numBitsPerFrame = FrameSize * numBitsPerSample;
numTotalSamples = SecondsOfSpeech * Fs;
numTotalFrames = ceil(numTotalSamples/FrameSize);
%%%%%%%%%%%%%%%%%%%%%%%%% Speech Encoding loop %%%%%%%%%%%%%%%
txBitsAll=zeros(numBitsPerFrame*numTotalFrames,1);
prev=0;
for index=1:numTotalFrames
    y=step(LiveAudioSource);
    z=int16(32768*y(:,1));
    y1=(2^(params.DR-15))*z;
    % Speech encoding to G711
    txBits=speechEncode(y1, LawG711, params);
    pcm = speechDecode(txBits, LawG711, params);
    step(TxAudioFile, int16(4*pcm));
    txBitsAll(prev+(1:numBitsPerFrame)') = txBits;
    prev=prev+numBitsPerFrame;
end
fprintf(1,'File name = TxMusic.m4a \n\n');
release(LiveAudioSource);
release(TxAudioFile);
end