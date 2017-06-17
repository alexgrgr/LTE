function PlotReceivedResourceGrid(enb, rxGrid)
% Obtain resource grid colorization. Initialization of output
colors = ones(size(rxGrid));
% Determine subframe length 'L' (in OFDM symbols) and the number of 
% subframes 'nsf' in the input grid 
dims = lteDLResourceGridSize(enb);
L = dims(2);
nsf = size(rxGrid,2)/L;

% Initialization of PDSCH physical resource block set
enb.PDSCH.PRBSet = (0:enb.NDLRB-1).';

% Loop for each subframe
for i=0:nsf-1

    % Configure subframe number
    enb.NSubframe=mod(i,10);   

    % Create empty resource grid
    sfcolors = lteDLResourceGrid(enb);  

    % Colourize the Resource Elements for each channel and signal
    sfcolors(lteCellRSIndices(enb,0)) = 1;
    sfcolors(ltePSSIndices(enb,0)) = 2;
    sfcolors(lteSSSIndices(enb,0)) = 3;
    sfcolors(ltePBCHIndices(enb)) = 4;
    duplexingInfo = lteDuplexingInfo(enb);
     if (duplexingInfo.NSymbolsDL~=0)
         sfcolors(ltePCFICHIndices(enb)) = 5;
         sfcolors(ltePHICHIndices(enb)) = 6;
         sfcolors(ltePDCCHIndices(enb)) = 7;
         sfcolors(ltePDSCHIndices(enb,enb.PDSCH,enb.PDSCH.PRBSet)) = 8;
     end

     
     %%Only works for 1 antena. Retreiving just the first
    % Set current subframe into output
    colors(:,i*L+(1:L)) = colors(:,i*L+(1:L)) + sfcolors(:,1);
end

Level = colors;
colors =abs(rxGrid);

% If need to aggregate by 6 or 12
if Level > 1
    % Filter function by blocks of 6.
    H = size(colors,1);
    W = size(colors,2);
    Coarse = zeros(H/Level, W);
    
    % filter: keep the color that has the most hits in the 6x1 group
    for col = 1:W
        for row = 1:H/Level
            dist = histc(colors((row-1)*Level+(1:Level),col),1:10);
            [~,ind] = max(dist);
            Coarse(row,col) = ind;
        end
    end
    
    % Use filtered colors.
    colors = Coarse;
end

rgrid = ones(size(colors));

% Determine number of subcarriers 'K' and number of OFDM symbols 'L'
% in input resource grid
K = size(rgrid,1);
L = size(rgrid,2);

% Pad edges of resource grid and colors
rgrid = [zeros(K,1) rgrid zeros(K,2)];
rgrid = [zeros(1,L+3); rgrid; zeros(2,L+3)];
colors = [zeros(K,1) colors zeros(K,2)];
colors = [zeros(1,L+3); colors; zeros(1,L+3)];
for k = 1:K+3
    for l = L+3:-1:2
        if (rgrid(k,l)==0 && rgrid(k,l-1)~=0)
            rgrid(k,l) = rgrid(k,l-1);
        end
    end
end
for l = 1:L+3
    for k = K+3:-1:2
        if (rgrid(k,l)==0 && rgrid(k-1,l)~=0)
            rgrid(k,l) = rgrid(k-1,l);
        end
    end
end

% Create resource grid power matrix, with a floor of -40dB
powers = 20*log10(rgrid+1e-2);

% Create surface plot of powers
h = surf((-1:L+1)-0.5,(-1:K+1)-0.5,powers,colors);

% Create and apply color map
ColorArray = ListColors();
NrColors = size(ColorArray,1);
caxis([0 NrColors-1]);
colormap(ColorArray);
set(h,'EdgeColor',[0.25 0.25 0.25]);

% Set view and axis ranges
axis([-1.5 L+0.5 -1.5 K+0.5 min(powers(:))-5 max(powers(:))+5]);
view([-45 45]);

% Set plot axis labels
zlabel('Power (dB)');
ylabel('Subcarrier index');
xlabel('OFDM symbol index');

% Add plot title
title('Received resource grid');