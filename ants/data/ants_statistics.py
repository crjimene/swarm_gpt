import itertools
from pprint import pprint

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import kruskal, levene, mannwhitneyu
from sklearn.utils import resample
from statsmodels.stats.multitest import multipletests

sns.set_theme(style="whitegrid", font_scale=1.3)


def plot_statistical_results(results, **kwargs):
    # Prepare a DataFrame with the results for visualization
    stats_df = []
    for pair, res in results.items():
        stats_df.append(
            {
                "Comparison": pair,
                "Levene's p-value": res["Levene_p"],
                "Brown-Forsythe p-value": res["Brown-Forsythe_p"],
                "Cohen's d": np.abs(res["Cohen_d"]),
                "Kruskal p-value": res["Kruskal_p"],
            }
        )

    stats_df = pd.DataFrame(stats_df)

    # Create a new column for hue based on the first part of the comparison
    stats_df["Group"] = ["LLM", "NetLogo", "Hybrid"]

    # Create a grouped bar plot for the values
    plt.figure(figsize=(12, 6))
    comparison = stats_df.set_index("Comparison")
    print(comparison)
    sns.barplot(
        data=comparison,
        palette=kwargs["palette"],
    )
    plt.ylabel("Value")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    plt.show()

    # plot statistics side by side
    df = comparison.copy()
    df.reset_index(inplace=True)
    df.rename(columns={"index": "Comparison"}, inplace=True)

    # Melt the DataFrame to long format
    df_melted = df.melt(
        id_vars=["Comparison", "Group"],
        value_vars=[
            "Levene's p-value",
            "Brown-Forsythe p-value",
            "Cohen's d",
            "Kruskal p-value",
        ],
        var_name="Metric",
        value_name="Value",
    )
    plt.figure(figsize=kwargs["figsize"])
    p = sns.barplot(
        data=df_melted,
        x="Comparison",
        y="Value",
        hue="Metric",
        errorbar=None,
        palette=kwargs["palette"],
    )
    p.set_ylim(0.0, 0.25)
    p.set_xlabel("")
    p.legend(loc="center left", bbox_to_anchor=(1, 0.5), title="Metric")
    plt.ylabel("Value")
    # plt.legend(title="Metric")
    if kwargs["savefig"]:
        plt.savefig(
            "ants_statistics.jpg",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
            dpi=300,
        )
    plt.show()

    # Plot Cohen's d Effect Size
    plt.figure(figsize=(6, 6))
    sns.barplot(
        data=stats_df,
        x="Comparison",
        y=stats_df["Cohen's d"],
        palette="Set2",
        legend=False,
    )
    plt.title("Cohen's d Effect Size for Each Comparison")
    plt.ylabel("Effect Size")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    plt.show()


def cohens_d2(group1, group2):
    # Calculate the means of both groups
    mean1 = np.mean(group1)
    mean2 = np.mean(group2)

    # Calculate the standard deviations of both groups
    std1 = np.std(group1, ddof=1)  # Sample standard deviation
    std2 = np.std(group2, ddof=1)  # Sample standard deviation

    # Calculate the pooled standard deviation
    pooled_std = np.sqrt(
        ((len(group1) - 1) * std1**2 + (len(group2) - 1) * std2**2)
        / (len(group1) + len(group2) - 2)
    )

    # Calculate Cohen's d
    d = (mean1 - mean2) / pooled_std
    return d


def cohens_d(group1, group2):
    mean_diff = np.mean(group1) - np.mean(group2)
    pooled_std = np.sqrt(((np.std(group1) ** 2) + (np.std(group2) ** 2)) / 2)
    return mean_diff / pooled_std


def analyze_differences(df):
    cols = df.columns
    results = {}
    for i in range(len(df.columns)):
        for j in range(i + 1, len(df.columns)):
            g1 = df[cols[i]]
            g2 = df[cols[j]]
            print(f"group1 {cols[i]}, group2 {cols[j]}")
            # Levene's Test (for equal variances)
            levene_stat, levene_p = levene(
                g1, g2, center="median"
            )  # More robust with median

            # Brown-Forsythe Test (uses median instead of mean)
            bf_stat, bf_p = levene(g1, g2, center="mean")

            cohen_d = cohens_d2(g1, g2)
            # Kruskal-Wallis test across all groups
            kruskal_stat, kruskal_p = kruskal(g1, g2)

            # Store results for the current pair of models
            pair_name = f"{cols[i]} vs {cols[j]}"
            results[pair_name] = {
                "Levene_p": levene_p,
                "Brown-Forsythe_p": bf_p,
                "Cohen_d": cohen_d,
                "Kruskal_p": kruskal_p,
            }

    return results


if __name__ == "__main__":
    # overall plot configurations
    kwargs = {
        "figsize": (12, 6),
        "palette": "Set2",
        "bbox_inches": "tight",
        "pad_inches": 0.1,
        "savefig": True,
    }

    file_paths = [
        (
            f"food_collected_llm_seed_{i}.csv",
            f"food_collected_netlogo_seed_{i}.csv",
            f"food_collected_hybrid_seed_{i}.csv",
        )
        for i in range(1, 6)
    ]
    group1 = np.mean([pd.read_csv(fi[0])["food_amount"] for fi in file_paths], axis=0)
    group2 = np.mean([pd.read_csv(fi[1])["food_amount"] for fi in file_paths], axis=0)
    group3 = np.mean([pd.read_csv(fi[2])["food_amount"] for fi in file_paths], axis=0)
    data = {"LLM": group1, "NetLogo": group2, "Hybrid": group3[:1000]}
    combined_df = pd.DataFrame(data)
    results = analyze_differences(combined_df)
    pprint(results)
    # Visualize the results
    plot_statistical_results(results, **kwargs)
