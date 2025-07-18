# ECG Beat Classification using SVM

This is the course project that implements an ECG beat classification pipeline using the Pan-Tompkins algorithm for QRS detection and a Support Vector Machine (SVM) for classifying heart beats as **normal** or **abnormal**.

##  Features

- Preprocessing using the Pan-Tompkins QRS detection pipeline
- Feature extraction based on morphological and temporal characteristics
- ECG beat classification using SVM (RBF kernel)
- Visualization of detected beats and classification results
- Custom `.txt` to `.csv` annotation conversion for the MIT-BIH dataset


## Dataset

We use the **MIT-BIH Arrhythmia Database** for training and evaluation.

- **Official Source:**  
  [https://www.physionet.org/physiobank/database/html/mitdbdir/mitdbdir.htm](https://www.physionet.org/physiobank/database/html/mitdbdir/mitdbdir.htm)

- **Download Interface (for .mat & annotation files) (No WFDB required)::**  
  [https://archive.physionet.org/cgi-bin/atm/ATM](https://archive.physionet.org/cgi-bin/atm/ATM)

Download ECG signals as `.mat` files and annotations as `.txt`, and place them in:


##  Extracted Features

1. QS interval width  
2. Pre-RR interval  
3. Post-RR interval  
4. QR interval width  
5. RS interval width  
6. Mean power spectral density  
7. Area under QR segment  
8. Area under RS segment
9. 
<img width="727" height="455" alt="ECG Segment" src="https://github.com/user-attachments/assets/4b275b07-5afb-4025-bca5-089e19d32233" />

##  Requirements

- MATLAB (tested on R2023b or later)
- MIT-BIH Arrhythmia Dataset `.mat` and `.txt` files
- Corresponding annotation `.txt` files

##  Usage

1. Place the MIT-BIH `.mat` and `annotations.txt` into the `dataset/<record>/` folder.
2. Convert annotations (From text to CSV)  **No need for WFDB Toolbox or wfdb-swig-matlab.**
   ```matlab
   run annotation_conversion.m
3. To test classification and visualization beats.
   ```matlab
   run main.m 
<img width="718" height="455" alt="ECGPlot" src="https://github.com/user-attachments/assets/d2b2fdc8-7899-4f22-bee6-ad73d7cf532c" />
