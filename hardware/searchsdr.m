function SDRTx = searchsdr
connectedRadios = findsdru;
if strncmp(connectedRadios(1).Status, 'Success', 7)
  SDRTx.Platform = connectedRadios(1).Platform;
  switch connectedRadios(1).Platform
    case {'B200','B210'}
      SDRTx.Address = connectedRadios(1).SerialNum;
    case {'N200/N210/USRP2','X300','X310'}
      SDRTx.Address = connectedRadios(1).IPAddress;
  end
else
  fprintf(' No radio found. Please, connect the radio\n');
end