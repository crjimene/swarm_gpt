import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from mpl_toolkits.axes_grid1.inset_locator import mark_inset

# Set the style of seaborn
sns.set_theme(style="whitegrid", font_scale=1.3)


def collected_food(file_paths: list, step_number: int = 20, **kwargs) -> None:
    """
    Plot the average amount of food collected over time for different models (LLM, NetLogo, Hybrid).
    This function generates a line plot with an inset showing a zoomed-in view of a specific range.

    :param file_paths: List of tuples of str
        Each tuple contains file paths for the LLM, NetLogo, and Hybrid CSV files to load.
    :param step_number: int, optional
        The step interval for filtering the data. Default is 20.
    :param kwargs: Additional keyword arguments for plot customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # Use a list comprehension to load and label the DataFrames
    dataframes = [
        pd.concat(
            [
                pd.read_csv(llm_file).assign(source="LLM"),
                pd.read_csv(netlogo_file).assign(source="NetLogo"),
                pd.read_csv(hybrid_file).assign(source="Hybrid")[:999],
            ],
            ignore_index=True,
        )
        for llm_file, netlogo_file, hybrid_file in file_paths
    ]

    # Concatenate all DataFrames in the list into a single DataFrame
    final_df = pd.concat(dataframes, ignore_index=True)

    # Take every nth step
    filtered_data = final_df[final_df["step_number"] % step_number == 0]

    # Create a plot
    plt.figure(figsize=kwargs["figsize"])
    d = sns.lineplot(
        data=filtered_data,
        x="step_number",
        y="food_amount",
        hue="source",
        palette=kwargs["palette"],
    )
    # get axes for inset
    axes = d.axes
    x1, x2, y1, y2 = 0, 100, -1, 10
    axins = axes.inset_axes(
        [0.01, 0.25, 0.25, 0.25], xlim=(x1, x2), ylim=(y1, y2), yticklabels=[]
    )
    axins.tick_params(
        axis="x", labelsize=10
    )  # Decrease the fontsize of the inset xticks
    d = sns.lineplot(
        data=filtered_data,
        x="step_number",
        y="food_amount",
        hue="source",
        palette=kwargs["palette"],
        ax=axins,
    )
    d.set(xlabel=None, ylabel=None)
    d.get_legend().set_visible(False)
    mark_inset(axes, axins, loc1=3, loc2=4, fc="none", ec="0.7")

    # Adding titles and labels
    plt.xlabel("Step Number")
    plt.ylabel("Food Amount")
    plt.legend(title=kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "collected_food_amount_hybrid.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    # Show the plot
    plt.show()


def steps_return_food(file_paths: list, **kwargs) -> None:
    """
    Plot the average time (in steps) taken for food return by ants for each food source.
    This function generates a box plot to visualize the distribution of steps for different models.

    :param file_paths: List of tuples of str
        Each tuple contains file paths for the LLM, NetLogo, and Hybrid CSV files to load.
    :param kwargs: Additional keyword arguments for plot customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # load and label the DataFrames
    dataframes = []
    for llm_file, netlogo_file, hybrid_file in file_paths:
        dataframes.append(
            pd.read_csv(llm_file, names=["Food Patch", "Steps"]).assign(source="LLM")
        )
        dataframes.append(
            pd.read_csv(netlogo_file, names=["Food Patch", "Steps"]).assign(
                source="NetLogo"
            )
        )
        dataframes.append(
            pd.read_csv(hybrid_file, names=["Food Patch", "Steps"]).assign(
                source="Hybrid"
            )
        )

    # Concatenate all DataFrames in the list into a single DataFrame
    final_df = pd.concat(dataframes, ignore_index=True)
    # Print out statistics
    print(final_df.groupby(["Food Patch", "source"])["Steps"].describe())

    # Create a box plot
    plt.figure(figsize=kwargs["figsize"])
    g = sns.boxplot(
        data=final_df,
        x="Food Patch",
        y="Steps",
        hue="source",
        palette=kwargs["palette"],
    )
    # Change the title of the legend
    legend = g.get_legend()
    legend.set_title(kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "steps_return_food.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


def steps_search_food(file_paths: list, **kwargs) -> None:
    """
    Plot the average time (in steps) taken for ants to search for food for each food source.
    This function generates a box plot to visualize the distribution of steps for different models.

    :param file_paths: List of tuples of str
        Each tuple contains file paths for the LLM, NetLogo, and Hybrid CSV files to load.
    :param kwargs: Additional keyword arguments for customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # load and label the DataFrames
    dataframes = []
    for llm_file, netlogo_file, hybrid_file in file_paths:
        dataframes.append(
            pd.read_csv(llm_file, names=["Food Patch", "Steps"]).assign(source="LLM")
        )
        dataframes.append(
            pd.read_csv(netlogo_file, names=["Food Patch", "Steps"]).assign(
                source="NetLogo"
            )
        )
        dataframes.append(
            pd.read_csv(hybrid_file, names=["Food Patch", "Steps"]).assign(
                source="Hybrid"
            )
        )

    # Concatenate all DataFrames in the list into a single DataFrame
    final_df = pd.concat(dataframes, ignore_index=True)
    # Print out statistics
    print(final_df.groupby(["Food Patch", "source"])["Steps"].describe())
    # Create a box plot
    plt.figure(figsize=kwargs["figsize"])
    g = sns.boxplot(
        data=final_df,
        x="Food Patch",
        y="Steps",
        hue="source",
        palette=kwargs["palette"],
    )
    # Change the title of the legend
    legend = g.get_legend()
    legend.set_title(kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "steps_search_food.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


if __name__ == "__main__":
    # overall plot configurations
    kwargs = {
        "figsize": (12, 6),
        "palette": "Set2",
        "bbox_inches": "tight",
        "pad_inches": 0.1,
        "legend_title": "Model Variant",
        "savefig": False,
    }

    # Figure 3
    # Define the list of file paths
    file_paths = [
        (
            f"food_collected_llm_seed_{i}.csv",
            f"food_collected_netlogo_seed_{i}.csv",
            f"food_collected_hybrid_seed_{i}.csv",
        )
        for i in range(1, 6)
    ]
    collected_food(file_paths, **kwargs)

    # figure 4
    # Define the list of file paths
    file_paths = [
        (
            f"AntColony_LLM_Seed_{i}_wayback_duration.csv",
            f"AntColony_Netlogo_Seed_{i}_wayback_duration.csv",
            f"AntColony_Hybrid_Seed_{i}_wayback_duration.csv",
        )
        for i in range(1, 6)
    ]
    steps_return_food(file_paths, **kwargs)

    # figure 5
    # Define the list of file paths
    file_paths = [
        (
            f"AntColony_LLM_Seed_{i}_search_duration.csv",
            f"AntColony_Netlogo_Seed_{i}_search_duration.csv",
            f"AntColony_Hybrid_Seed_{i}_search_duration.csv",
        )
        for i in range(1, 6)
    ]
    steps_search_food(file_paths, **kwargs)
