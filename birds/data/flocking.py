import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

sns.set_theme(style="whitegrid", font_scale=1.3)


# Define helper function to classify birds
def classify_bird(bird_id):
    return "Hybrid (LLM)" if bird_id <= 4 else "Hybrid (NetLogo)"


def heading_differences(
    file_paths: list, rule_based_file_paths: list, **kwargs
) -> None:
    """
    Plot the differences in bird headings over time for different models (LLM, NetLogo, Hybrid).

    :param file_paths: List of str
        List of file paths for the CSV files containing heading difference data.
    :param rule_based_file_paths: List of str
        List of file paths for the CSV files containing rule-based heading difference data.
    :param kwargs: Additional keyword arguments for customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # Load all files into a list of DataFrames
    data_list = [pd.read_csv(file_path) for file_path in file_paths]
    data_list_rule_based = [
        pd.read_csv(file_path) for file_path in rule_based_file_paths
    ]

    # Add bird classification columns and filter unique birds
    for data in data_list:
        data["bird1_type"] = data["bird1_id"].apply(classify_bird)
        data["bird2_type"] = data["bird2_id"].apply(classify_bird)

    # Combine data from all datasets
    combined_data = pd.concat(data_list, ignore_index=True)
    combined_data_rb = pd.concat(data_list_rule_based, ignore_index=True)
    combined_data_rb["bird1_type"] = pd.Series(
        (["NetLogo" for x in range(len(combined_data_rb.index))])
    )

    # Filter for unique bird pairs by enforcing bird1_id < bird2_id
    unique_data = combined_data[combined_data["bird1_id"] < combined_data["bird2_id"]]
    unique_data_rb = combined_data_rb[
        combined_data_rb["bird1_id"] < combined_data_rb["bird2_id"]
    ]

    # Plot the raw heading differences
    plt.figure(figsize=kwargs["figsize"])
    unique_data = unique_data.sort_values(
        by="bird1_type",
        key=lambda col: col.map({"Hybrid (LLM)": 0, "Hybrid (NetLogo)": 1}),
    )
    unique_data_combined = pd.concat(
        [unique_data, unique_data_rb], ignore_index=True, sort=False
    )
    sns.lineplot(
        data=unique_data_combined,
        x="step_number",
        y="heading_difference",
        hue="bird1_type",
        palette=kwargs["palette"],
        alpha=0.7,
        markers=True,
    )
    # plt.title("Heading Differences of LLM and NetLogo Birds")
    plt.xlabel("Step Number")
    plt.ylabel("Heading Difference")
    plt.legend(title=kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "heading_differences_hybrid_rule-based.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


def distances(file_paths: list, rule_based_file_paths: list, **kwargs) -> None:
    """
    Plot the distances between birds over time for different models.

    :param file_paths: List of str
        List of file paths for the CSV files containing distance data.
    :param rule_based_file_paths: List of str
        List of file paths for the CSV files containing rule-based distance data.
    :param kwargs: Additional keyword arguments for customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # Load all files into a list of DataFrames
    data_list = [pd.read_csv(file_path) for file_path in file_paths]
    data_list_rule_based = [
        pd.read_csv(file_path) for file_path in rule_based_file_paths
    ]

    # Add bird classification columns and filter unique birds
    for data in data_list:
        data["bird1_type"] = data["bird1_id"].apply(classify_bird)
        data["bird2_type"] = data["bird2_id"].apply(classify_bird)

    # Combine data from all datasets
    combined_data = pd.concat(data_list, ignore_index=True)
    combined_data_rb = pd.concat(data_list_rule_based, ignore_index=True)
    combined_data_rb["bird1_type"] = pd.Series(
        (["NetLogo" for x in range(len(combined_data_rb.index))])
    )

    # Filter for unique bird pairs by enforcing bird1_id < bird2_id
    unique_data = combined_data[combined_data["bird1_id"] < combined_data["bird2_id"]]
    unique_data_rb = combined_data_rb[
        combined_data_rb["bird1_id"] < combined_data_rb["bird2_id"]
    ]

    # Plot the raw heading differences
    plt.figure(figsize=kwargs["figsize"])
    unique_data = unique_data.sort_values(
        by="bird1_type",
        key=lambda col: col.map({"Hybrid (LLM)": 0, "Hybrid (NetLogo)": 1}),
    )
    unique_data_combined = pd.concat(
        [unique_data, unique_data_rb], ignore_index=True, sort=False
    )
    sns.lineplot(
        data=unique_data_combined,
        x="step_number",
        y="distance",
        hue="bird1_type",
        palette=kwargs["palette"],
        alpha=0.7,
        markers=True,
    )
    plt.xlabel("Step Number")
    plt.ylabel("Distances")
    plt.legend(title=kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "distances_hybrid_rule-based.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


def percentile(n):
    def percentile_(x):
        return x.quantile(n)

    percentile_.__name__ = "percentile_{:02.0f}".format(n * 100)
    return percentile_


def number_neighbours(file_paths: list, rule_based_file_paths: list, **kwargs) -> None:
    """
    Calculate and visualize the average number of neighbors for birds over time.

    :param file_paths: List of str
        List of file paths for the CSV files containing neighbor data.
    :param rule_based_file_paths: List of str
        List of file paths for the CSV files containing NetLogo neighbor data.
    :param kwargs: Additional keyword arguments for customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # Load all files into a list of DataFrames
    data_list = [pd.read_csv(file_path) for file_path in file_paths]
    data_list_rule_based = [
        pd.read_csv(file_path) for file_path in rule_based_file_paths
    ]

    # Function to calculate average number of neighbors for LLM and NetLogo birds
    def calculate_neighbors(data, step_number=50, distance=5):
        # Add bird classification columns
        data["bird1_type"] = data["bird1_id"].apply(classify_bird)
        data["bird2_type"] = data["bird2_id"].apply(classify_bird)

        # Filter data for 1 < distances <= 5 and every 50th iteration
        # Distance > 1 because we don't count collisions
        filtered_data = data[
            (data["distance"] <= distance)
            & (data["distance"] > 1)
            & (data["step_number"] % step_number == 0)
        ]

        # Calculate average neighbors for LLM birds
        llm_neighbors = (
            filtered_data[filtered_data["bird1_id"] <= 4]
            .groupby(["step_number", "bird1_id"])["bird2_id"]
            .nunique()
            .groupby("step_number")
            .mean()
            .reset_index()
        )
        llm_neighbors["bird_type"] = "Hybrid (LLM)"

        # Calculate average neighbors for NetLogo birds
        netlogo_neighbors = (
            filtered_data[filtered_data["bird1_id"] > 4]
            .groupby(["step_number", "bird1_id"])["bird2_id"]
            .nunique()
            .groupby("step_number")
            .mean()
            .reset_index()
        )
        netlogo_neighbors["bird_type"] = "Hybrid (NetLogo)"

        # Combine the results into a single DataFrame
        combined_neighbors = pd.concat(
            [llm_neighbors, netlogo_neighbors], ignore_index=True
        )
        combined_neighbors.rename(
            columns={"bird2_id": "average_neighbors"}, inplace=True
        )

        return combined_neighbors

    # Apply the function to each dataset and combine results
    neighbors_list = [calculate_neighbors(data) for data in data_list]
    neighbors_data = pd.concat(neighbors_list, ignore_index=True)

    # also calculate the collision for rule based
    neighbors_list_rb = []
    for data in data_list_rule_based:
        filtered_data = data[
            (data["distance"] <= 5)
            & (data["distance"] > 1)
            & (data["step_number"] % 50 == 0)
        ]
        group = (
            filtered_data.groupby(["step_number", "bird1_id"])["bird2_id"]
            .nunique()
            .groupby("step_number")
            .mean()
            .reset_index()
        )
        group["bird_type"] = "NetLogo"
        neighbors_list_rb.append(group)

    # concat rule based list
    neighbors_data_rb = pd.concat(neighbors_list_rb, ignore_index=True)
    neighbors_data_rb.rename(columns={"bird2_id": "average_neighbors"}, inplace=True)
    # combine everything
    combined = pd.concat(
        [neighbors_data, neighbors_data_rb], sort=False, ignore_index=True
    )
    # Print some statistics
    statistics = combined.groupby("bird_type")["average_neighbors"].agg(
        [
            "count",
            "mean",
            "median",
            "std",
            "min",
            percentile(0.25),
            percentile(0.50),
            percentile(0.75),
            "max",
        ]
    )
    print(statistics)

    # Visualization
    plt.figure(figsize=kwargs["figsize"])
    sns.boxplot(
        data=combined,
        x="step_number",
        y="average_neighbors",
        hue="bird_type",
        palette=kwargs["palette"],
    )

    # Add labels and title
    plt.xlabel("Step Number")
    plt.ylabel("Number of Neighbors")
    # plt.title('Number of Collisions')
    plt.legend(title=kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "average_neighbors_d_all.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


def collisions(
    file_paths: list, rule_based_file_paths: list, distance: int = 1, **kwargs
) -> None:
    """
    Calculate and visualize the number of collisions between birds over time.

    :param file_paths: List of str
        List of file paths for the CSV files containing collision data.
    :param rule_based_file_paths: List of str
        List of file paths for the CSV files containing rule-based collision data.
    :param distance: int, optional
        The distance threshold for defining a collision. Default is 1.
    :param kwargs: Additional keyword arguments for customization.
        - figsize: tuple, size of the figure (width, height).
        - palette: str, name of color scheme.
        - legend_title: str, title for the legend.
        - savefig: bool, whether to save the figure as a PDF.
        - bbox_inches: str, bounding box for saving the figure.
        - pad_inches: float, padding for saving the figure.

    :return: None
    """
    # Load all files into a list of DataFrames
    data_list = [pd.read_csv(file_path) for file_path in file_paths]
    data_list_rule_based = [
        pd.read_csv(file_path) for file_path in rule_based_file_paths
    ]

    # Function to calculate collisions for LLM and NetLogo birds
    def calculate_collisions(data):
        # Add bird classification columns
        data["bird1_type"] = data["bird1_id"].apply(classify_bird)
        data["bird2_type"] = data["bird2_id"].apply(classify_bird)

        # Filter data for collisions (distance <= 1)
        collision_data = data[data["distance"] <= distance]

        # Count collisions for LLM birds
        llm_collisions = (
            collision_data[collision_data["bird1_id"] <= 4]
            .groupby("step_number")["bird1_id"]
            .count()
            .reset_index()
        )
        llm_collisions["bird_type"] = "Hybrid (LLM)"

        # Count collisions for NetLogo birds
        netlogo_collisions = (
            collision_data[collision_data["bird1_id"] > 4]
            .groupby("step_number")["bird1_id"]
            .count()
            .reset_index()
        )
        netlogo_collisions["bird_type"] = "Hybrid (NetLogo)"

        # Combine the results into a single DataFrame
        combined_collisions = pd.concat(
            [llm_collisions, netlogo_collisions], ignore_index=True
        )
        combined_collisions.rename(
            columns={"bird1_id": "collision_count"}, inplace=True
        )
        return combined_collisions

    # Apply the function to each dataset and combine results
    collisions_list = [calculate_collisions(data) for data in data_list]
    collisions_data = pd.concat(collisions_list, ignore_index=True)
    # also calculate the collision for rule based
    collisions_list_rb = []
    for data in data_list_rule_based:
        filtered_data = data[(data["distance"] <= distance)]
        group = filtered_data.groupby("step_number")["bird1_id"].count().reset_index()
        group["bird_type"] = "NetLogo"
        collisions_list_rb.append(group)
    collision_data_rb = pd.concat(collisions_list_rb, ignore_index=True)
    collision_data_rb.rename(columns={"bird1_id": "collision_count"}, inplace=True)
    # combine everything
    combined = pd.concat(
        [collisions_data, collision_data_rb], sort=False, ignore_index=True
    )
    # Visualization
    plt.figure(figsize=kwargs["figsize"])
    sns.lineplot(
        data=combined,
        x="step_number",
        y="collision_count",
        hue="bird_type",
        palette=kwargs["palette"],
    )

    # Overlay Line Plot in case of barplot
    # sns.lineplot(data=collisions_data, x='step_number', y='collision_count', hue='bird_type', marker='o', legend=False)

    # Add labels and title
    plt.xlabel("Step Number")
    plt.ylabel("Number of Collisions")
    # plt.title('Number of Collisions')
    plt.legend(title=kwargs["legend_title"])
    if kwargs["savefig"]:
        plt.savefig(
            "collisions_all.pdf",
            bbox_inches=kwargs["bbox_inches"],
            pad_inches=kwargs["pad_inches"],
        )
    plt.show()


if __name__ == "__main__":
    # overall configurations
    kwargs = {
        "figsize": (12, 6),
        "palette": "Set2",
        "bbox_inches": "tight",
        "pad_inches": 0.1,
        "legend_title": "Model Variant",
        "savefig": False,
    }

    # Figure 7
    # Load CSV files
    file_paths = [f"headingsdiff_flockdata_seed_{i}.csv" for i in range(1, 6)]
    rule_based_file_paths = [
        f"headingsdiff_flockdata_rulebased_seed_{i}.csv" for i in range(1, 6)
    ]
    heading_differences(file_paths, rule_based_file_paths, **kwargs)

    # Figure 8
    # Load CSV files
    file_paths = [f"distances_flockdata_seed_{i}.csv" for i in range(1, 6)]
    rule_based_file_paths = [
        f"distances_flockdata_rulebased_seed_{i}.csv" for i in range(1, 6)
    ]
    distances(file_paths, rule_based_file_paths, **kwargs)

    # Figure 9
    # Load CSV files
    file_paths = [
        "distances_flockdata_seed_1.csv",
        "distances_flockdata_seed_2.csv",
        "distances_flockdata_seed_3.csv",
        "distances_flockdata_seed_4.csv",
        "distances_flockdata_seed_5.csv",
    ]
    rule_based_file_paths = [
        f"distances_flockdata_rulebased_seed_{i}.csv" for i in range(1, 6)
    ]
    collisions(file_paths, rule_based_file_paths, **kwargs)

    # Figure 10
    number_neighbours(file_paths, rule_based_file_paths, **kwargs)
