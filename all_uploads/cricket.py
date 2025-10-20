import numpy as np
import matplotlib.pyplot as plt


def compute_fantasy_points(runs: np.ndarray, balls_faced: np.ndarray) -> np.ndarray:
    """
    Compute fantasy points for each player in each match.
    """
    # TODO: Implement scoring rules using NumPy broadcasting and masking
    sr = 100*runs/balls_faced
    sr = np.where(sr == np.inf, 0, sr)
    hc_bonus = np.where(sr>=50, 10, 0)
    hsr_bonus = np.where(sr>150, 5, 0)
    return runs+hc_bonus+hsr_bonus


def plot_player1_vs_player2(runs: np.ndarray, player1_index: int, player2_index: int, filename: str):
    """
    Plots and saves a line chart showing the runs per match for:
    - player1
    - player2

    Saves the figure as filename

    Arguments:
    - runs: np.ndarray of same shape
    - player1_index: int index of the player1 to plot
    - player2_index: int index of the player2 to plot

    Plot Requirements:
    - Title: "Fantasy Points Comparison"
    - x-axis label: "Matches"
    - y-axis label: "Runs"
    - x-ticks: 0 to n_matches-1
    - Line for Player_1: red with circles ('o-r'), label = "Player {player1_index}"
    - Line for Player_2: blue with squares ('s-b'), label = "Player {player_index}"
    - No grid
    - Show legends
    - Use figsize=(10, 5)
    - Call `plt.tight_layout()` before saving'
    """
    plt.figure(figsize=(10, 5))
    plt.title("Fantasy Points Comparison")
    plt.ylabel("Runs")
    plt.xlabel("Matches")
    plt.tight_layout()
    n_matches = runs.shape[1]
    plt.plot(np.arange(n_matches), runs[player1_index], 'o-r', label = "Player {player1_index}")
    plt.plot(np.arange(n_matches), runs[player2_index], 's-b', label = "Player {player_index}")
    plt.legend()
    plt.xticks(np.arange(n_matches))
    plt.savefig(filename)




def average_points_above_ball_threshold(runs: np.ndarray, balls_faced: np.ndarray, threshold: int = 20) -> np.ndarray:
    """
    Compute average fantasy points only for matches where player faced > threshold balls.
    returns an 1d array of averages for each player.
    """
    # TODO: Mask and compute mean only for qualifying matches
    pass
