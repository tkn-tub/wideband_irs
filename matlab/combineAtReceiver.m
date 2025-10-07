function combined = combineAtReceiver(op, includeCrossIndices, carrier, pdsch, N_sub_list, N)
% COMBINEATRECEIVER Combine op's own RX plus selected cross contributions.
% op: operator struct (output from simulateOperator)
% includeCrossIndices: indices of op.cross to include (e.g. [1 2] or [] )
%
% Returns combined struct with fields:
%   .rxCombinedNoisless, .rxCombinedWithNoise, .SNR_dB, .mean_SNR_partial

    if nargin < 2 || isempty(includeCrossIndices)
        includeCrossIndices = [];
    end


    rxCombinedNoisless = op.rxWaveformNoisless;
    noise_comb=op.noise;


    for i = includeCrossIndices
        rxCombinedNoisless = rxCombinedNoisless + op.cross(i).rxWaveformNoisless;
        noise_comb = noise_comb + op.cross(i).noise;
    end

    
    rxCombinedWithNoise = rxCombinedNoisless + noise_comb;


    rxGrid_comb = hpre6GOFDMDemodulate(carrier, rxCombinedWithNoise);
    H_comb = nrChannelEstimate(rxGrid_comb, op.dmrsInd, op.dmrsSym);
    noiseGrid = hpre6GOFDMDemodulate(carrier, noise_comb);

    P_signal = mean(abs(H_comb).^2, 2);
    P_noise  = mean(abs(noiseGrid).^2, 2);
    SNR_dB = 10*log10(P_signal ./ P_noise);

    % differen BWs
    mean_SNR_partial = zeros(length(N_sub_list),1);
    for idx = 1:length(N_sub_list)
        N_sub = N_sub_list(idx);
        mean_SNR_partial(idx) = mean(SNR_dB(1:N_sub));
    end

    % return
    combined = struct();
    combined.rxCombinedNoisless = rxCombinedNoisless;
    combined.rxCombinedWithNoise = rxCombinedWithNoise;
    combined.SNR_dB = SNR_dB;
    combined.mean_SNR_partial = mean_SNR_partial;
    combined.noise_comb = noise_comb;
end
