import numpy as np
import matplotlib.pyplot as plt

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
    for datetime in datetimes[1:]:
        if datetime == prev: count += 1
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
    plt.xticks(rotation=30)
    plt.gca().xaxis.set_major_formatter(plt.matplotlib.dates.DateFormatter('%Y-%m-%d %H:%M:%S'))
    plt.plot(dt, counts)
    plt.savefig('static/line.png', bbox_inches='tight')
    
# Save pie chart
def pie_chart(states):
    # counting states
    notices, errors = 0, 0
    for state in states:
        if state == 'notice': notices += 1
        elif state == 'error': errors += 1

    plt.title('State Level Distribution')
    plt.pie([notices, errors], labels=['notice', 'error'])
    plt.savefig('static/pie.png', bbox_inches='tight')

# Save bar graph
def bar_graph(event_codes):
    # counting events
    events = [f'E{i}' for i in range(1, 7)]
    event_counts = [0 for _ in range(6)]
    for event_code in event_codes:
        if 1 <= event_code and event_code <= 6:
            event_counts[event_code-1] += 1

    plt.title('Event Code Distribution')
    plt.bar(events, event_counts, color='r', width=0.5)
    plt.savefig('static/bar.png', bbox_inches='tight')

# Read CSV, then plot graphs
def plot_stuff():
    with open(graphs_output_file_path, newline='') as file:
        lines = [line.strip().split(',') for line in file]
        datetimes = [line[1][20:]+'-'+
                 month_to_number(line[1][4:7])+'-'+
                 line[1][8:10]+'T'+
                 line[1][11:19] for line in lines[1:]]
        states = [line[2] for line in lines[1:]]
        event_codes = [int(line[4][1]) for line in lines[1:]]
    
    plt.figure(figsize=(15, 10))
    line_plot(datetimes)
    plt.close()

    plt.figure(figsize=(15, 10))
    pie_chart(states)
    plt.close()

    plt.figure(figsize=(15, 10))
    bar_graph(event_codes)
    plt.close()

