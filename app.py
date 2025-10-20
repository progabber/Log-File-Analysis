from flask import Flask, render_template, request, send_file, redirect, url_for, flash
import matplotlib
matplotlib.use('Agg') # running on a server, so use non-GUI backend
# from official docs: "Agg is a non-interactive backend that can only write to files"
import matplotlib.pyplot as plt
import numpy as np
import os
import subprocess
import csv

from graphs import graph_apache
from graphs import graph_android
from graphs import graph_system

app = Flask(__name__)
app.secret_key = 'nahin bataunga' # used for flask's flash() utility

# all uploads will be stored here, one of these will
# be chosen by the user as the log file to process
all_upload_dir = 'all_uploads'

input_file_path = 'uploads/input_file'
upload_output_file_path = 'processed/upload.csv'
graphs_output_file_path = 'processed/graphs.csv'

if not os.path.exists(all_upload_dir):
    os.makedirs(all_upload_dir)

# empty the general upload folder
for filename in os.listdir(all_upload_dir):
    filepath = os.path.join(all_upload_dir, filename)
    if os.path.isfile(filepath):
        os.remove(filepath)

file_uploaded = False
log_format = "" # apache, android or system (linux)

# Home page - where user uploads files and is given the
# option to view the CSV, download it or plot graphs
@app.route('/')
def upload_webpage():
    files = os.listdir(all_upload_dir)
    if len(files) > 0:
        return render_template('log_upload.html', files=files)
    return render_template('log_upload.html')

# Accept user uploads for possibly multiple files
@app.route('/upload_log', methods=['POST'])
def upload_file():
    files = request.files.getlist('file')
    
    # Save files in all_upload_dir
    for file in files:
        filepath = os.path.join(all_upload_dir, file.filename)
        file.save(filepath)

    return redirect(url_for('upload_webpage'))

# Handle choosing of file by the user
@app.route('/choose_file', methods=['POST'])
def choose_file():
    # selected_file is the string chosen from the drop down
    selected_file = request.form['chosen_file']
    subprocess.run(['cp', os.path.join(all_upload_dir, selected_file), input_file_path])
    
    # Check for encoding and alert if bytes
    with open(input_file_path, 'r') as input_file:
        try:
            file_contents = input_file.read()
        except UnicodeDecodeError:
            flash("Invalid pro max...BYTES my application")
            redirect(url_for('upload_webpage'))

    global file_uploaded
    file_uploaded = True

    files = os.listdir(all_upload_dir)
    if len(files) > 0:
        return render_template('log_upload.html', files=files, filename=selected_file)

    return render_template('log_upload.html', filename=file.filename)

# Accept datetime range for processing the logfile 
@app.route('/set_range/<selected_file>', methods=['POST'])
def set_range(selected_file):
    sdate = request.form['sdate']
    stime = request.form['stime']
    edate = request.form['edate']
    etime = request.form['etime']

    make_csv(sdate, stime, edate, etime)

    # Check if data exists in entered range
    with open(upload_output_file_path, 'r') as upload_csv:
        num_lines = len(upload_csv.readlines())
    if num_lines <= 1: 
        flash("No data in the given range, please choose the file again")
        return redirect(url_for('upload_webpage'))

    files = os.listdir(all_upload_dir)
    if len(files) > 0:
        return render_template('log_upload.html', files=files, filename=selected_file)

    return render_template('log_upload.html', filename=selected_file)

# Allow the user to download the processed CSV
@app.route('/download_log')
def download_file():
    global file_uploaded
    if not file_uploaded: 
        flash("Please upload a log first")
        return redirect(url_for('upload_webpage'))

    return send_file(upload_output_file_path, as_attachment=True)

# Convert the downloaded raw log into CSV by calling the bash script
def make_csv(sdate, stime, edate, etime):
    global log_format
    global upload_output_file_path

    log_format = subprocess.run(["bash", "bash/make_csv.sh", sdate, stime, edate, etime, upload_output_file_path],
                                capture_output=True, text=True).stdout.strip()
    print(log_format)
    if log_format == "Error":
        flash("Log format invalid. Please try again.")
        return redirect(url_for('upload_webpage'))

    return upload_output_file_path

# Show the processed CSV as a table on a new page
@app.route('/display_log')
def show_table():
    global file_uploaded
    if not file_uploaded: 
        flash("Please upload a log first")
        return redirect(url_for('upload_webpage'))

    '''
    -------------------NOTE---------------------
    For Apache logs, use of CSV module was not allowed, 
    So given below is the code for the same
    
    for Apache logs (without using csv module)
    with open(upload_output_file_path, newline='') as csvfile:
        data = [line.strip().split(',') for line in csvfile]
        headers = data[0]
        rows = data[1:]

    '''
    # for the general case
    with open(upload_output_file_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        data = list(reader)
        headers = data[0]
        rows = data[1:]

    return render_template('log_display.html', headers=headers, rows=rows)

# Plot graphs, take user input for datetime range
@app.route('/graphs')
def graphs_webpage():
    global log_format
    if log_format == 'Error':
        flash("Log format invalid. Please try again.")
        return redirect(url_for('upload_webpage'))
    
    global file_uploaded
    if not file_uploaded: 
        flash("Please upload a log first")
        return redirect(url_for('upload_webpage'))
    return render_template('graphs.html')

# Process the graphs form and plot graphs
@app.route('/graphs_form', methods=['POST'])
def plot_the_graphs():
    ''' Actual plotting logic '''
    global log_format
    global file_uploaded
    if not file_uploaded: 
        flash("Please upload a log first")
        return redirect(url_for('upload_webpage'))

    sdate = request.form['sdate']
    stime = request.form['stime']
    edate = request.form['edate']
    etime = request.form['etime']

    log_format = subprocess.run(["bash", "bash/make_csv.sh", sdate, stime, edate, etime, graphs_output_file_path],
                                capture_output=True, text=True).stdout.strip()

    # Check if data exists in entered range
    with open(graphs_output_file_path, 'r') as graphs_csv:
        num_lines = len(graphs_csv.readlines())
    if num_lines == 1: 
        flash("No data in the given range")
        return redirect(url_for('graphs_webpage'))

    if log_format == "apache": graph_apache.plot_stuff()
    elif log_format == "android": graph_android.plot_stuff()
    elif log_format == "system": graph_system.plot_stuff()

    return render_template('graphs.html', file_uploaded=file_uploaded)

# Download .png of plots where <type> = [line | pie | bar]
@app.route('/download/<type>')
def download_line(type):
    graph_path = f'static/{type}.png'
    return send_file(graph_path, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)
