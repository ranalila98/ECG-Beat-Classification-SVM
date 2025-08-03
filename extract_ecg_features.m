% function [features, R_loc, Q_loc, S_loc, P_loc, T_loc, n_beats_det, left_ind, right_ind] = extract_ecg_features(ecg_m, ecg_MW, fs)
% %EXTRACT_ECG_FEATURES Extract ECG features and wave locations from processed signal
% %   Inputs:
% %       ecg_m  - mean-subtracted and normalized ECG
% %       ecg_MW - output after MWI step
% %       fs     - sampling frequency (Hz)
% %   Outputs:
% %       features     - feature matrix
% %       R_loc        - R-peak locations
% %       Q_loc        - Q-peak locations
% %       S_loc        - S-peak locations
% %       P_loc        - P-peak locations
% %       T_loc        - T-peak locations
% %       n_beats_det  - number of detected beats
% %       left_ind     - left bounds of possible QRS
% %       right_ind    - right bounds of possible QRS
% 
%     ts = 1/fs;
% 
%     % Thresholding and region boundaries
%     poss_reg = (ecg_MW > mean(ecg_MW))';
%     left_ind = find(diff([0 poss_reg.']) == 1).';
%     right_ind = find(diff([poss_reg.' 0]) == -1).';
% 
%     % R, Q, S detection
%     R_loc = zeros(numel(left_ind), 1);
%     Q_loc = zeros(numel(left_ind), 1);
%     S_loc = zeros(numel(left_ind), 1);
%     for i = 1:numel(left_ind)
%         [~, R_loc(i)] = max(ecg_m(left_ind(i):right_ind(i)));
%         R_loc(i) = R_loc(i)-1+left_ind(i);
%         [~, Q_loc(i)] = min(ecg_m(left_ind(i):R_loc(i)));
%         Q_loc(i) = Q_loc(i)-1+left_ind(i);
%         [~, S_loc(i)] = min(ecg_m(R_loc(i):right_ind(i)));
%         S_loc(i) = S_loc(i)-1+R_loc(i);
%     end
% 
%     % Clean incomplete edges
%     if R_loc(1)*ts < 0.2
%         Q_loc(1) = []; R_loc(1) = []; S_loc(1) = [];
%         left_ind(1) = []; right_ind(1) = [];
%     end
%     if (numel(ecg_m)-R_loc(end))*ts < 0.2
%         Q_loc(end) = []; R_loc(end) = []; S_loc(end) = [];
%         left_ind(end) = []; right_ind(end) = [];
%     end
%     n_beats_det = numel(R_loc);
% 
%     % P and T detection
%     P_loc = zeros(n_beats_det, 1);
%     T_loc = zeros(n_beats_det, 1);
%     for i = 1:n_beats_det
%         pL = max(1, left_ind(i) - round(0.2 * fs));
%         pR = left_ind(i);
%         [~, p] = max(ecg_m(pL:pR));
%         P_loc(i) = pL + p - 1;
% 
%         tL = right_ind(i);
%         tR = min(numel(ecg_m), tL + round(0.4 * fs));
%         [~, t] = max(ecg_m(tL:tR));
%         T_loc(i) = tL + t - 1;
%     end
% 
%     % Feature Extraction
%     RS_width = ts * (S_loc - R_loc);
%     QS_width = ts * (S_loc - Q_loc);
%     QR_width = ts * (R_loc - Q_loc);
%     pre_RR_int = [0; ts * diff(R_loc)];
%     post_RR_int = [pre_RR_int(2:end); 0];
% 
%     MPSD = zeros(n_beats_det, 1);
%     area_QR = zeros(n_beats_det, 1);
%     area_RS = zeros(n_beats_det, 1);
%     for i = 1:n_beats_det
%         MPSD(i) = mean(abs(fft(ecg_m(P_loc(i):T_loc(i)))).^2);
%         area_QR(i) = trapz(ecg_m(Q_loc(i):R_loc(i)));
%         area_RS(i) = trapz(ecg_m(R_loc(i):S_loc(i)));
%     end
% 
%     features = [QS_width, pre_RR_int, post_RR_int, QR_width, RS_width, MPSD, area_QR, area_RS];
% end

function [features, R_loc, Q_loc, S_loc, P_loc, T_loc, n_beats_det, left_ind, right_ind] = extract_ecg_features(ecg_m, ecg_MW, fs, template_normal)

    ts = 1/fs;

    % === Thresholding and region detection ===
    poss_reg = (ecg_MW > mean(ecg_MW))';
    left_ind = find(diff([0 poss_reg.']) == 1).';
    right_ind = find(diff([poss_reg.' 0]) == -1).';

    % === R, Q, S detection ===
    R_loc = zeros(numel(left_ind), 1);
    Q_loc = zeros(numel(left_ind), 1);
    S_loc = zeros(numel(left_ind), 1);
    for i = 1:numel(left_ind)
        [~, R_loc(i)] = max(ecg_m(left_ind(i):right_ind(i)));
        R_loc(i) = R_loc(i) - 1 + left_ind(i);
        [~, Q_loc(i)] = min(ecg_m(left_ind(i):R_loc(i)));
        Q_loc(i) = Q_loc(i) - 1 + left_ind(i);
        [~, S_loc(i)] = min(ecg_m(R_loc(i):right_ind(i)));
        S_loc(i) = S_loc(i) - 1 + R_loc(i);
    end

    % === Clean boundaries ===
    if R_loc(1)*ts < 0.2
        Q_loc(1) = []; R_loc(1) = []; S_loc(1) = [];
        left_ind(1) = []; right_ind(1) = [];
    end
    if (numel(ecg_m)-R_loc(end))*ts < 0.2
        Q_loc(end) = []; R_loc(end) = []; S_loc(end) = [];
        left_ind(end) = []; right_ind(end) = [];
    end
    n_beats_det = numel(R_loc);

    % === P and T detection ===
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

    % === Initialize feature arrays ===
    QS_width = zeros(n_beats_det,1);
    QR_width = zeros(n_beats_det,1);
    RS_width = zeros(n_beats_det,1);
    pre_RR_int = [0; ts * diff(R_loc)];
    post_RR_int = [pre_RR_int(2:end); 0];
    MPSD = zeros(n_beats_det,1);
    area_QR = zeros(n_beats_det,1);
    area_RS = zeros(n_beats_det,1);
    auto_corr_val = zeros(n_beats_det,1);
    ST_dev = zeros(n_beats_det,1);
    ST_slope = zeros(n_beats_det,1);
    template_corr = zeros(n_beats_det,1);

    for i = 1:n_beats_det
        % === Duration Features ===
        QS_width(i) = ts * (S_loc(i) - Q_loc(i));
        QR_width(i) = ts * (R_loc(i) - Q_loc(i));
        RS_width(i) = ts * (S_loc(i) - R_loc(i));

        % === MPSD ===
        if P_loc(i) < T_loc(i)
            window = ecg_m(P_loc(i):T_loc(i));
            MPSD(i) = mean(abs(fft(window)).^2);
        else
            MPSD(i) = 0;
        end

        % === Area under QR, RS ===
        if Q_loc(i) < R_loc(i)
            area_QR(i) = trapz(ecg_m(Q_loc(i):R_loc(i)));
        else
            area_QR(i) = 0;
        end
        if R_loc(i) < S_loc(i)
            area_RS(i) = trapz(ecg_m(R_loc(i):S_loc(i)));
        else
            area_RS(i) = 0;
        end

        % === Autocorrelation ===
        if Q_loc(i) < S_loc(i)
            segment = ecg_m(Q_loc(i):S_loc(i));
            if length(segment) >= 2
                acf = xcorr(segment, 'coeff');
                acf(acf == 1 | isnan(acf)) = [];  % Remove trivial peak
                auto_corr_val(i) = max(acf(:), [], 'omitnan');
            else
                auto_corr_val(i) = 0;
            end
        else
            auto_corr_val(i) = 0;
        end

        % === ST deviation and slope ===
        st_start = S_loc(i) + round(0.02 * fs);
        st_end   = min(T_loc(i), numel(ecg_m));
        if st_end > st_start
            y = ecg_m(st_start:st_end);
            x = (st_start:st_end) * ts;
            ST_dev(i) = mean(y);
            p = polyfit(x, y, 1);
            ST_slope(i) = p(1);
        else
            ST_dev(i) = 0;
            ST_slope(i) = 0;
        end

        % === Correlation with normal template ===
        if Q_loc(i) < S_loc(i)
            beat_seg = ecg_m(Q_loc(i):S_loc(i));
            if length(beat_seg) >= 2 && length(template_normal) >= 2
                beat_seg = interp1(1:length(beat_seg), beat_seg, ...
                    linspace(1,length(beat_seg), length(template_normal)), 'linear', 'extrap');
                c = corrcoef(beat_seg, template_normal);
                if size(c,1)==2 && size(c,2)==2
                    template_corr(i) = c(1,2);
                else
                    template_corr(i) = 0;
                end
            else
                template_corr(i) = 0;
            end
        else
            template_corr(i) = 0;
        end
    end

    % === Final Feature Matrix (12 features) ===
    features = [QS_width, pre_RR_int, post_RR_int, ...
                QR_width, RS_width, MPSD, ...
                area_QR, area_RS, auto_corr_val, ...
                ST_dev, ST_slope, template_corr];
end
