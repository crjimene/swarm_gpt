from pprint import pprint

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import kruskal, levene

sns.set_theme(style="whitegrid", font_scale=1.3)


def cohens_d(group1, group2):
    mean_diff = np.mean(group1) - np.mean(group2)
    pooled_std = np.sqrt(((np.std(group1) ** 2) + (np.std(group2) ** 2)) / 2)
    return mean_diff / pooled_std


def analyze_differences(g1, g2):
    """
    Analyze differences in standard deviation between experimental groups.
    Performs:
    1. Levene's test for equal variances
    2. Brown-Forsythe test (variant of Levene)
    3. Bootstrap confidence intervals for std deviations
    4. Coefficient of Variation (CV)
    5. Cohen's d (Effect Size)
    """
    # Levene's Test (for equal variances)
    levene_stat, levene_p = levene(g1, g2, center="median")  # More robust with median

    # Brown-Forsythe Test (uses median instead of mean)
    bf_stat, bf_p = levene(g1, g2, center="mean")

    # Cohen's d (Effect Size)
    cohen_d = cohens_d(g1, g2)
    print("Cohen finished")
    kruskal_stat, kruskal_p = kruskal(g1, g2)
    print("Kruskal-Wallis finished")
    # Store results for the current pair of models
    results = {}
    results = {
        "Levene's p-value": levene_p,
        "Brown-Forsythe p-value": bf_p,
        "Cohen's d": cohen_d,
        "Kruskal p-value": kruskal_p,
    }

    return results


def plot_statistical_results(results, **kwargs):
    # Prepare a DataFrame with the results for visualization
    stats_df = pd.DataFrame([results])
    plt.figure(figsize=kwargs["figsize"])
    p = sns.barplot(data=stats_df, palette=kwargs["palette"])
    plt.ylabel("Value")
    p.set_xlabel("Hybrid vs. NetLogo")
    plt.tight_layout()
    if kwargs["savefig"]:
        plt.savefig(
            "birds_statistics.jpg",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
            dpi=300,
        )
    plt.show()


if __name__ == "__main__":
    # Plot configurations
    kwargs = {
        "figsize": (12, 6),
        "palette": "Set2",
        "bbox_inches": "tight",
        "pad_inches": 0.1,
        "savefig": True,
    }
    file_paths = [f"headingsdiff_flockdata_seed_{i}.csv" for i in range(1, 6)]
    rule_based_file_paths = [
        f"headingsdiff_flockdata_rulebased_seed_{i}.csv" for i in range(1, 6)
    ]

    # Load all files into a list of DataFrames
    data_list = [pd.read_csv(file_path) for file_path in file_paths]
    data_list_rule_based = [
        pd.read_csv(file_path) for file_path in rule_based_file_paths
    ]
    group1 = np.mean([df["heading_difference"] for df in data_list], axis=0)
    group2 = np.mean([df["heading_difference"] for df in data_list_rule_based], axis=0)
    print("Groups finished")

    results = analyze_differences(group1, group2)
    pprint(results)
    plot_statistical_results(results, **kwargs)
