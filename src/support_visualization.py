
# data visualization imports
import matplotlib.pyplot as plt 
import matplotlib.dates as mdates
import seaborn as sns

def plot_line_labels(ax, interval=1, contrast=False):
    if not isinstance(contrast, bool):
        raise TypeError(f"Expected 'contrast' to be of type 'bool', but got {type(contrast).__name__} instead.")
    
    for line in ax.lines:
        line_color = line.get_color()  # Get the color of the line

        if contrast:
            # Convert the color to a perceived brightness value
            r, g, b = line.get_color()[:3]  # Extract RGB values
            brightness = (r * 299 + g * 587 + b * 114) / 1000  # Perceived brightness formula

            # Set text color based on brightness (black text for bright backgrounds, white text for dark backgrounds)
            text_color = 'white' if brightness < 0.5 else 'black'
        else:
            text_color = 'white'

        for it, (x_data, y_data) in enumerate(zip(line.get_xdata(), line.get_ydata())):
            if it % interval == 0:
                ax.text(
                    x_data, y_data, f'{y_data:.0f}', 
                    ha='center', va='bottom',
                    color=text_color,  # Set the chosen text color
                    bbox=dict(facecolor=line_color, edgecolor='none', alpha=0.8)  # Set background color matching the line color
                )


def create_time_xticks(ax,hour_interval=1, format='%m/%d %H:00', rotation=45):
    ax.xaxis.set_major_locator(mdates.HourLocator(interval=hour_interval))
    ax.xaxis.set_major_formatter(mdates.DateFormatter(format))
    ax.tick_params(axis='x', rotation=rotation)