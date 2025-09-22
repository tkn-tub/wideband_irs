function op = simulateOperator(fc, carrier,ofdmInfo, pdsch, txArraySize, txPower, ...
                               N_sub_list, N, risSize, maxDistance, existingOps)
% SIMULATEOPERATOR Create an operator struct and compute own RX + cross reflections.
% existingOps: array (1 x K) of previously created operator structs.
%
% Outputs: op struct with fields:
%   .fc, .ris, .risCh, .risElementCoeff, .w
%   .posTx, posRIS, posRx
%   .txWaveform, .channelDelay, .offsetTxRIS, .offsetRISRx
%   .rxWaveformNoisless, .noise, .rxWaveformWithNoise
%   .SNR_dB, .mean_SNR_partial
%   .cross (array of cross contributions computed using existingOps)

    if nargin < 11
        existingOps = [];
    end

    c = physconst("lightspeed");

    % Prepare op struct
    op = struct();
    op.fc = fc;
    op.ris.Size = risSize;
    op.ris.Enable = true;
    op.ris.dx = (c/fc)/5;
    op.ris.dy = (c/fc)/5;
    op.ris.A  = 0.8;

    % Build RIS channel object
    op.risCh = hpre6GRISChannel("SampleRate",ofdmInfo.SampleRate, ...
        "RISSize",op.ris.Size, ...
        "CarrierFrequency",fc, ...
        "DelayProfileTxRIS","CDL-C", ...
        "DelayProfileRISRx","CDL-C");
    op.risCh.TransmitAntennaArray.Size = txArraySize;
    op.risCh.ReceiveAntennaArray.Size = [1 1 1 1 1];
    op.risCh.Seed = randi([0,(2^30)-1]);

    % channel delay
    chInfo = op.risCh.info;
    op.channelDelay = chInfo.TxRISChInfo.MaximumChannelDelay + chInfo.RISRXChInfo.MaximumChannelDelay;

    % random positions for MC simulations
    valid = false;
    while ~valid
        op.posTx  = rand(1,3)*maxDistance;
        op.posRIS = rand(1,3)*maxDistance;
        op.posRx  = rand(1,3)*maxDistance;
        dTxRIS = norm(op.posRIS - op.posTx);
        dRISRx = norm(op.posRIS - op.posRx);
        if dTxRIS <= maxDistance && dRISRx <= maxDistance
            valid = true;
        end
    end

    % Path loss (Tx -> RIS -> Rx) for own RIS
    dTxRIS = norm(op.posRIS - op.posTx);
    dRISRx = norm(op.posRIS - op.posRx);
    PL_own = ((4*pi*dTxRIS*dRISRx)/(prod(op.ris.Size(1:3))*op.ris.dx*op.ris.dy*op.ris.A))^2;

    % RIS coefficients and precoding
    [op.risElementCoeff, op.w, ~] = calculateRISCoeff(op.ris.Enable, op.risCh, carrier);
    op.w = op.w.'; % format for generateTxWaveform

    % Generate transmit waveform
    [txWaveform, pdschSym, pdschInd, dmrsSym, dmrsInd, waveformInfo, pdschGrid] = ...
        generateTxWaveform(carrier, pdsch, op.w, txPower);
    op.txWaveform = [txWaveform; zeros(op.channelDelay, size(txWaveform,2))];

    % offsets
    [~,~,op.offsetTxRIS, op.offsetRISRx] = op.risCh.channelResponse(carrier);

    % Send through own RIS channel (noiseless), apply path loss
    rxNoiseless_full = op.risCh(op.txWaveform, op.risElementCoeff);
    op.rxWaveformNoisless_raw = (1/sqrt(PL_own)) * rxNoiseless_full;

    op.rxWaveformNoisless = op.rxWaveformNoisless_raw(1 + op.offsetTxRIS + op.offsetRISRx : end, :);


    op.noise = sqrt(N) * randn(size(op.rxWaveformNoisless),"like",op.rxWaveformNoisless);
    op.rxWaveformWithNoise = op.rxWaveformNoisless + op.noise;


    op.pdschInd = pdschInd;
    op.dmrsSym  = dmrsSym;
    op.dmrsInd  = dmrsInd;

    % OFDM demod + channel estimation for own RX
    rxGrid = hpre6GOFDMDemodulate(carrier, op.rxWaveformWithNoise);
    noiseGrid = hpre6GOFDMDemodulate(carrier, op.noise);
    H = nrChannelEstimate(rxGrid, op.dmrsInd, op.dmrsSym);

    % Per-subcarrier SNR for own RX
    P_signal = mean(abs(H).^2, 2);
    P_noise  = mean(abs(noiseGrid).^2, 2);
    op.SNR_dB = 10*log10(P_signal ./ P_noise);

    %SNR for N_sub_list (different BWs)
    op.mean_SNR_partial = zeros(length(N_sub_list),1);
    for idx = 1:length(N_sub_list)
        N_sub = N_sub_list(idx);
        op.mean_SNR_partial(idx) = mean(op.SNR_dB(1:N_sub));
    end

    % ---------------------------
    % CROSS contributions (Tx of this operator through OTHER IRSs)
    % ---------------------------
    op.cross = [];
    for k = 1:length(existingOps)
        other = existingOps(k);
        % distances: Tx(op) -> RIS(other) -> Rx(op)
        dTxRIS_cross = norm(other.posRIS - op.posTx);
        dRISRx_cross = norm(other.posRIS - op.posRx);

        PL_cross = ((4*pi*dTxRIS_cross*dRISRx_cross)/(prod(other.ris.Size(1:3))*other.ris.dx*other.ris.dy*other.ris.A))^2;

        % Pass this operator's txWaveform through the other operator's risCh
        rx_noiseless_cross_full = other.risCh(op.txWaveform, other.risElementCoeff);
        rx_noiseless_cross = (1/sqrt(PL_cross)) * rx_noiseless_cross_full;

        % Trim cross waveform to match the target (op) length for safe addition:
        targetLen = size(op.rxWaveformNoisless,1);
        rx_noiseless_cross_trim = rx_noiseless_cross(1:min(targetLen,size(rx_noiseless_cross,1)), :);


        if size(rx_noiseless_cross_trim,1) < targetLen
            rx_noiseless_cross_trim(end+1:targetLen, :) = 0;
        end

        crossEntry = struct();
        crossEntry.sourceOpIndex = k;
        crossEntry.otherOp = other; 
        crossEntry.rxWaveformNoisless = rx_noiseless_cross_trim;


        crossEntry.PL = PL_cross;
        crossEntry.dTxRIS = dTxRIS_cross;
        crossEntry.dRISRx = dRISRx_cross;


        crossEntry.noise = sqrt(N) * randn(size(crossEntry.rxWaveformNoisless), "like", crossEntry.rxWaveformNoisless);
        crossEntry.rxWaveformWithNoise = crossEntry.rxWaveformNoisless + crossEntry.noise;

        op.cross = [op.cross, crossEntry];
    end

end
