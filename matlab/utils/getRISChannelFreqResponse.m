
function [G,h] = getRISChannelFreqResponse(risCh,carrier)
    % Calculate the overall RIS channel response averaging the 
    % channel response, that is, one channel matrix for the whole
    % bandwidth, and not per resource element. 
    [TxRISGrid,RISRxGrid] = channelResponse(risCh,carrier);
    
    h = zeros(size(RISRxGrid,3),size(RISRxGrid,4));
    RISRxGrid = mean(RISRxGrid,[1 2]); % assume flat in time and freq
    h(:,:) = RISRxGrid(1,1,:,:);

    G = zeros(size(TxRISGrid,3),size(TxRISGrid,4));
    TxRISGrid = mean(TxRISGrid,[1 2]); % assume flat in time and freq
    G(:,:) = TxRISGrid(1,1,:,:);
end
