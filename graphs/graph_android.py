import numpy as np
import matplotlib.pyplot as plt
import csv

graphs_output_file_path = 'processed/graphs.csv'

# Return the numerical repr of 3-char month str 
def month_to_number(month):
    months = 'JanFebMarAprMayJunJulAugSepOctNovDec'
    month = month.capitalize()
    i = months.find(month)
    return '%02d' % (i//3 + 1)

# Save line graph
def line_plot(datetimes):
    # counting datetimes
    prev = datetimes[0]
    count = 1
    counts = []
    cleaned_dt = []
    for datetime in datetimes[1:-1]:
        print("This is datetime:\t", datetime)
        if datetime[:-4] == prev[:-4]: count += 1
        else:
            cleaned_dt.append(prev)
            counts.append(count)
            prev = datetime
            count = 1

    if datetimes[-1][:-4] == prev[:-4]: count += 1
    cleaned_dt.append(datetimes[-1])
    counts.append(count)

    plt.title('Events logged vs Time')
    dt = np.array(cleaned_dt, dtype='datetime64')
    print(dt, counts)
    plt.xticks(rotation=30)
    plt.gca().xaxis.set_major_formatter(plt.matplotlib.dates.DateFormatter('%m-%d %H:%M:%S'))
    plt.plot(dt, counts)
    plt.savefig('static/line.png', bbox_inches='tight')
    
# Save pie chart
def pie_chart(levels):
    # counting levels
    level_count = {}
    for level in levels:
        level_count[level] = level_count.get(level, 0) + 1

    plt.title('Level Breakdown')
    plt.pie(level_count.values(), labels=level_count.keys())
    plt.savefig('static/pie.png', bbox_inches='tight')

# Save bar graph
def bar_graph(components):
    # counting components
    component_count = {}
    for component in components:
        component_count[component] = component_count.get(component, 0) + 1

    plt.title('Component Distribution')
    plt.xticks(rotation=90)
    plt.bar(component_count.keys(), component_count.values(), color='r', width=0.5)
    plt.savefig('static/bar.png', bbox_inches='tight')

# Read CSV, then plot graphs
def plot_stuff():
    with open(graphs_output_file_path, newline='') as file:
        reader = csv.reader(file)
        lines = list(reader)
        datetimes = ['2020-' + line[1] + 'T' + 
                     line[2] for line in lines[1:]]
        components = [line[6] for line in lines[1:]]
        levels = [line[5] for line in lines[1:]]

    plt.figure(figsize=(15, 10))
    line_plot(datetimes)
    plt.close()

    plt.figure(figsize=(15, 10))
    pie_chart(levels)
    plt.close()

    plt.figure(figsize=(15, 10))
    bar_graph(components)
    plt.close()

