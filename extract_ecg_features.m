function [features, R_loc, Q_loc, S_loc, P_loc, T_loc, n_beats_det, left_ind, right_ind] = extract_ecg_features(ecg_m, ecg_MW, fs)
%EXTRACT_ECG_FEATURES Extract ECG features and wave locations from processed signal
%   Inputs:
%       ecg_m  - mean-subtracted and normalized ECG
%       ecg_MW - output after MWI step
%       fs     - sampling frequency (Hz)
%   Outputs:
%       features     - feature matrix
%       R_loc        - R-peak locations
%       Q_loc        - Q-peak locations
%       S_loc        - S-peak locations
%       P_loc        - P-peak locations
%       T_loc        - T-peak locations
%       n_beats_det  - number of detected beats
%       left_ind     - left bounds of possible QRS
%       right_ind    - right bounds of possible QRS

    ts = 1/fs;

    % Thresholding and region boundaries
    poss_reg = (ecg_MW > mean(ecg_MW))';
    left_ind = find(diff([0 poss_reg.']) == 1).';
    right_ind = find(diff([poss_reg.' 0]) == -1).';

    % R, Q, S detection
    R_loc = zeros(numel(left_ind), 1);
    Q_loc = zeros(numel(left_ind), 1);
    S_loc = zeros(numel(left_ind), 1);
    for i = 1:numel(left_ind)
        [~, R_loc(i)] = max(ecg_m(left_ind(i):right_ind(i)));
        R_loc(i) = R_loc(i)-1+left_ind(i);
        [~, Q_loc(i)] = min(ecg_m(left_ind(i):R_loc(i)));
        Q_loc(i) = Q_loc(i)-1+left_ind(i);
        [~, S_loc(i)] = min(ecg_m(R_loc(i):right_ind(i)));
        S_loc(i) = S_loc(i)-1+R_loc(i);
    end

    % Clean incomplete edges
    if R_loc(1)*ts < 0.2
        Q_loc(1) = []; R_loc(1) = []; S_loc(1) = [];
        left_ind(1) = []; right_ind(1) = [];
    end
    if (numel(ecg_m)-R_loc(end))*ts < 0.2
        Q_loc(end) = []; R_loc(end) = []; S_loc(end) = [];
        left_ind(end) = []; right_ind(end) = [];
    end
    n_beats_det = numel(R_loc);

    % P and T detection
    P_loc = zeros(n_beats_det, 1);
    T_loc = zeros(n_beats_det, 1);
    for i = 1:n_beats_det
        pL = max(1, left_ind(i) - round(0.2 * fs));
        pR = left_ind(i);
        [~, p] = max(ecg_m(pL:pR));
        P_loc(i) = pL + p - 1;

        tL = right_ind(i);
        tR = min(numel(ecg_m), tL + round(0.4 * fs));
        [~, t] = max(ecg_m(tL:tR));
        T_loc(i) = tL + t - 1;
    end

    % Feature Extraction
    RS_width = ts * (S_loc - R_loc);
    QS_width = ts * (S_loc - Q_loc);
    QR_width = ts * (R_loc - Q_loc);
    pre_RR_int = [0; ts * diff(R_loc)];
    post_RR_int = [pre_RR_int(2:end); 0];

    MPSD = zeros(n_beats_det, 1);
    area_QR = zeros(n_beats_det, 1);
    area_RS = zeros(n_beats_det, 1);
    for i = 1:n_beats_det
        MPSD(i) = mean(abs(fft(ecg_m(P_loc(i):T_loc(i)))).^2);
        area_QR(i) = trapz(ecg_m(Q_loc(i):R_loc(i)));
        area_RS(i) = trapz(ecg_m(R_loc(i):S_loc(i)));
    end

    features = [QS_width, pre_RR_int, post_RR_int, QR_width, RS_width, MPSD, area_QR, area_RS];
end
