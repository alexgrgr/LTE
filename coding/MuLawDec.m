function lin=MuLawDec(mu, MuDecRepresentatives)
% MuLawDec			Convert Mu-Law 8-bit PCM values into linear PCM values
%
% Usage:			lin=MuLawDec(mu,MuDEcRepresentatives);
%
% Input 			mu  = Mu-Law PCM values between 0 to 255
%					(8 bit dynamic range)
%                       MuDecRepresentatives = Lookup table for Mu to linear conversion
%
% Output			lin = Scalar integer numbers between (-2^13) and (2^13 - 1)
%				      (14 bit dynamic range)
% 

% Copyright 2003 The MathWorks, Inc.

%Now look up the decoder representative table using the same index
lin=MuDecRepresentatives(mu+1);
