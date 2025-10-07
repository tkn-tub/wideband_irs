import scipy.io
import os
import numpy as np
import matplotlib.pyplot as plt

# Load Data
folder_path = ""

snr_coexistence_raw = scipy.io.loadmat(os.path.join(folder_path, "mean_SNR_partial_21.mat"))["all_mean_SNR_21"]
snr_standalone_raw  = scipy.io.loadmat(os.path.join(folder_path, "mean_SNR_partial_2.mat"))["all_mean_SNR_2"]

# Bandwidths (MHz)
bandwidths = np.array([10, 20, 40, 80, 160, 320, 480, 640, 960, 1280])

# Helper: Remove Outliers
def remove_outliers(data, threshold=5):
    """Remove outliers using IQR method, threshold defines multiplier."""
    q1 = np.nanpercentile(data, 25, axis=0)
    q3 = np.nanpercentile(data, 75, axis=0)
    iqr = q3 - q1
    lower, upper = q1 - threshold * iqr, q3 + threshold * iqr
    return np.where((data < lower) | (data > upper), np.nan, data)

# Remove outliers
snr_coexistence = remove_outliers(snr_coexistence_raw, threshold=5)
snr_standalone  = remove_outliers(snr_standalone_raw, threshold=5)

# Statistics for All Data
range_min = np.nanmin(snr_coexistence, axis=0)
range_max = np.nanmax(snr_coexistence, axis=0)
q1_all    = np.nanpercentile(snr_coexistence, 25, axis=0)
q3_all    = np.nanpercentile(snr_coexistence, 75, axis=0)

#  Negatively Impacted Data
filtered_snr = np.where(snr_standalone > snr_coexistence, snr_coexistence, np.nan)
valid_counts = np.sum(~np.isnan(filtered_snr), axis=0)
print("Valid samples (per BW):", valid_counts)

q1_filtered = np.nanpercentile(filtered_snr, 25, axis=0)
q3_filtered = np.nanpercentile(filtered_snr, 75, axis=0)

# Plotting
plt.figure(figsize=(8, 4))

# Range (All Data)
plt.fill_between(bandwidths, range_min, range_max, color="b", alpha=0.1, label="Range (All Data)")
# IQR (All Data)
plt.fill_between(bandwidths, q1_all, q3_all, color="b", alpha=0.2, label="IQR (All Data)")
# IQR (Filtered Negatively Impacted Data)
plt.fill_between(bandwidths, q1_filtered, q3_filtered, color="r", alpha=0.6, label="IQR (Negatively Impacted)")

plt.xscale("log")
plt.xticks(bandwidths, labels=bandwidths, fontsize=10, rotation=45)
plt.xlabel("BW [MHz]", fontsize=12)
plt.ylabel(r"$\mathrm{SNR_1}$ [dB]", fontsize=12)

plt.grid(True, linestyle="--", alpha=0.7)
plt.legend(fontsize=11)
plt.tight_layout()
plt.show()
