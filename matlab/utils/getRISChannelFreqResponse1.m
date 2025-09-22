function [G, h, channelTot] = getRISChannelFreqResponse1(risCh, carrier, risElementCoeff)
    % Calculate the overall RIS channel response assuming the channel 
    % response is flat in time but not in frequency. The function returns 
    % the channel response such that for each subcarrier, the operation
    % HRISRX*diag(risElementCoeff)*HTXRIS is performed.
    
    % Get the frequency domain channel responses for Tx-to-RIS and RIS-to-Rx
    [TxRISGrid, RISRxGrid] = channelResponse(risCh, carrier);
    
    % Assume flat in time by averaging across the OFDM symbols (2nd dimension)
    TxRISGrid = mean(TxRISGrid, 2); % 1344-by-1-by-400-by-4
    RISRxGrid = mean(RISRxGrid, 2); % 1344-by-1-by-1-by-400

    % Assign TxRISGrid to G and RISRxGrid to h for output
    G = squeeze(mean(TxRISGrid,[2,4]));  % 1344-by-1-by-400-by-4
    h = squeeze(mean(RISRxGrid,2));  % 1344-by-1-by-1-by-400

    % Initialize the total channel response for each subcarrier
    numSubcarriers = size(RISRxGrid, 1); % 1344
    numRxAntennas = 1;  % Since `h` has a singleton dimension for Nr
    numTxAntennas = size(TxRISGrid, 4); % 4
    
    channelTot = zeros(numRxAntennas, numTxAntennas, numSubcarriers); % 1-by-4-by-1344

    % Perform the operation HRISRX*diag(risElementCoeff)*HTXRIS for each subcarrier
    for k = 1:numSubcarriers
        HTx = G(k,:);
        HRx = h(k,:);  % 1-by-400
        
            % Compute the channel response for subcarrier k
            channelTot(k) = HRx * diag(risElementCoeff) * HTx';  % 1-by-4

    end
            % channelTot = reshape(channelTot, [numSubcarriers, numTxAntennas, 1]);



end
