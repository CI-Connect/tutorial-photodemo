OSG Connect Tutorial: Photo Analysis Demo
=========================================

In this tutorial you will perform a very simple distributed analysis of approximately 5,000 digitized images from a photograph archive that associates an XML metadata file with each photo. This job will convert each JPEG image into an array of RGB color space tuples, and from them find the average luminance of the entire image. The result of each computation will be a pairing of average luminance with the year that the photo was taken. Jobs will write these results in JavaScript/JSON format, so that the results of all jobs in aggregate can be used to submit raw data into the Google Charts API and produce a straightforward scatter plot.
 
Source files will be retrieved on the fly over HTTP from Stash, the OSG Connect storage service. Results will be saved into Stash and made viewable in a web browser.
Login to OSG Connect
--------------------
  *If not already registered to OSG Connect, go to the [registration site](https://osgconnect.net) and follow instructions there.
  *Once registered, you are authorized to use **login.osgconnect.net** (the Condor submit host) and **stash.osgconnect.net** (the data host), in each case authenticating with your network ID (**netid**) and password:
```
$ ssh netid@login.osgconnect.net
```
Set up the tutorial
-------------------
This tutorial depends on several files that we have set up in advance:

  +**manifest.txt** - a prearranged input file associating the URL of a photo with the year it was taken
  +**djpeg** - a statically compiled executable to decode a JPEG file into PNM format (a simple array of RGB color values)
  +**luminance** - a Python program that selects a specified subset of the manifest, downloads the image over HTTP, runs it through DJPEG, and computes average luminance over the whole image
  +**scatter_pre.html** and **scatter_post.html** - HTML snippets that sandwich [year, luminance] tuples to produce a complete HTML file to plot the data using Google Charts.

Because these inputs and programs are not easy to type, the tutorial is available only using the tutorial command. Let's set up the photodemo tutorial:
```
$ tutorial photodemo 
Storage access demonstration using distributed photograph analysis
Tutorial 'photodemo' is set up.  To begin:
     cd ~/osg-photodemo
$ cd ~/osg-photodemo 
$ ls
```
Prepare and run the job
-----------------------
##### Create a submit file

When you have one large collection of inputs to distribute over many job slots, you can take either of two approaches:

  *break the input into many smaller inputs, and send a different input to each job instance;
  *send the whole input set with each job, but configure the job to perform its own selection on the input.
     
    To optimize performance over many thousands of jobs at slight expense to storage, the first approach is often better. For this tutorial, because the inputs are relatively few (~5500) – and in order to keep file management to a minimum – we will take the second approach. Each enqueued job will take the same input (manifest.txt), and its command line arguments will tell it which rows to work on. To produce a submit file with so many differing parameters, we have a shell script that outputs a Condor submit file.
     
    Run mksubmit to create a submit file. By default each resulting job will analyze 200 photos, so the job cluster uses about 28 slots. You can change the size of the cluster by chunking with a different value.
     
```
    # Use 28 slots of 200 photos each
    $ ./mksubmit 200 >photodemo.sub
    # Or use 56 slots of 100 photos each
    $ ./mksubmit 100 >photodemo.sub
```
##### Test the job locally

When setting up a new job type, it's important to **test your job outside of Condor* before submitting into the grid. Here is what a quick run over five photos would look like when it executes on a worker:
```
$ ./luminance 0 5 <manifest.txt 
/* Running on host: login01.osgconnect.net */
[1880, 0.525493],
[1919, 0.416121],
[1919, 0.436667],
[1919, 0.461788],
[1945, 0.142712],
/* 5 photos analyzed in 6.94s (1.39/s) */
```
This works, so we can feel comfortable scaling up.
##### Choose the Project Name

It is very important to set a project name using the +ProjectName = "project" parameter. A job without a ProjectName will fail with a message like:
```
No ProjectName ClassAd defined!
Please record your OSG project ID in your submit file.
  Example:  +ProjectName = "OSG-CO1234567"

Based on your username, here is a list of projects you might have 
access to:
ConnectTrain
OSG-Staff
```
To see the projects you belong to, you can use the command connect show-projects:
 
```
$ connect show-projects
Based on username (dgc), here is a list of projects you might have
access to:
ConnectTrain
OSG-Staff
```
You can join projects after you login at https://osgconnect.net/project-summary . Within minutes of joining and being approved for a project, you will have access via condor_submit as well. To define a new project, see [the ConnectBook section for Principal Investigators](https://confluence.grid.iu.edu/display/CON/Start+a+Project+with+OSG+Connect "Start a Project with OSG Connect").
 
Note: project names are case sensitive.

You have two ways to set the project name for your jobs:

  1.Add the +ProjectName="MyProject" line to the HTCondor submit file. **Remember to quote the project name!**
  2.Use the connect project command to select a default project for all your work.

Remember: if you do not set a project name, or you use a project that you're not a member of, then your job submission will fail.

##### Submit the job

Submit the job using condor_submit.
```
$ condor_submit photodemo.sub 
Submitting job(s)............................
28 job(s) submitted to cluster 181587.
```
##### Monitor job status

The condor_q command tells the status of currently running jobs. Generally you will want to limit it to your own jobs by giving it your own username:
```
$ condor_q netid
-- Submitter: login01.osgconnect.net : <192.170.227.195:42546> : login01.osgconnect.net
 ID      OWNER            SUBMITTED     RUN_TIME ST PRI SIZE CMD               
181587.0   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 0 200   
181587.1   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 200 200 
181587.2   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 400 200 
181587.3   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 600 200 
181587.4   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 800 200 
181587.5   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 1000 200
181587.6   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 1200 200
181587.7   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 1400 200
181587.8   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 1600 200
181587.9   netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 1800 200
181587.10  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 2000 200
181587.11  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 2200 200
181587.12  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 2400 200
181587.13  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 2600 200
181587.14  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 2800 200
181587.15  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 3000 200
181587.16  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 3200 200
181587.17  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 3400 200
181587.18  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 3600 200
181587.19  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 3800 200
181587.20  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 4000 200
181587.21  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 4200 200
181587.22  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 4400 200
181587.23  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 4600 200
181587.24  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 4800 200
181587.25  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 5000 200
181587.26  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 5200 200
181587.27  netid             4/8  05:00   0+00:02:53 R  0   0.0  luminance 5400 200
28 jobs; 0 completed, 0 removed, 0 idle, 28 running, 0 held, 0 suspended
```

If you want to see all jobs running on the system, use condor_q without any extra parameters.

Note the ST (state) column. Your job will be in the **I** state (idle) if it hasn't started yet. If it's currently scheduled and running, it will have state **R** (running). If it has completed already, it will not appear in condor_q.

Let's wait for your job to finish – that is, for condor_q not to show the job in its output. The connect watch command will give you semi-realtime updates on job status. Try it now. Press **control-C** to stop watching.

##### A bit about Stash

While waiting for jobs to complete, let's look a little more closely at what we've done. Take a peek at the **manifest.txt** file:
 
```
$ head -1 manifest.txt
http://stash.osgconnect.net/@ConnectTrain/photodemo/ucpa/series1/derivatives_series1/apf1-00001r.jpg 1880
```
 
Notice the format of the URL. Each project in OSG Connect has a space in Stash that is visible over HTTP. You can see it on the login node at /stash/projects/@<projectname>/public. (Above the public directory is private space for the project. Private space is not visible on the web, and you may set permissions to hide it from other OSG Connect users as well.) In fact, this entire tutorial is on public Stash: http://stash.osgconnect.net/@ConnectTrain/photodemo/tutorial
 
If you take a look there, you'll see all the tutorial files. Note that this is not your copy of the tutorial, which is private; it's the master copy that you set up your tutorial from. If you click on the entry for **manifest.txt** you can see all the URLs for all the photos. If you paste in a URL from that file, you'll see the photograph. You can download the Python code for the analysis, and so on. Stash is an important piece of the OSG Connect ecosystem; it makes your data available anywhere that your jobs run. Stash HTTP meshes nicely with Condor's native ability to transfer input from HTTP URLs, and if a worker endpoint uses an $http_proxy it will naturally see locality benefits.
 
Take a break while this job completes. Depending on the target resource, it can take anywhere from 3 minutes to 15 to run even when resources are immediately available.
 
Assess results
--------------
 
##### Job history

Once your job has finished, you can get information about its execution from the condor_history command:
```
$ condor_history 181587
 ID     OWNER          SUBMITTED   RUN_TIME     ST COMPLETED   CMD            
181587.7   netid           4/8  05:00   0+00:15:41 C   4/8  05:16 /home/netid/osg-photodemo/luminance 1400 200
181587.0   netid           4/8  05:00   0+00:15:24 C   4/8  05:15 /home/netid/osg-photodemo/luminance 0 200
181587.1   netid           4/8  05:00   0+00:14:40 C   4/8  05:15 /home/netid/osg-photodemo/luminance 200 200
181587.9   netid           4/8  05:00   0+00:14:10 C   4/8  05:14 /home/netid/osg-photodemo/luminance 1800 200
181587.10  netid           4/8  05:00   0+00:14:10 C   4/8  05:14 /home/netid/osg-photodemo/luminance 2000 200
181587.17  netid           4/8  05:00   0+00:13:49 C   4/8  05:14 /home/netid/osg-photodemo/luminance 3400 200
181587.13  netid           4/8  05:00   0+00:13:46 C   4/8  05:14 /home/netid/osg-photodemo/luminance 2600 200
181587.11  netid           4/8  05:00   0+00:13:45 C   4/8  05:14 /home/netid/osg-photodemo/luminance 2200 200
181587.19  netid           4/8  05:00   0+00:13:45 C   4/8  05:14 /home/netid/osg-photodemo/luminance 3800 200
181587.18  netid           4/8  05:00   0+00:13:41 C   4/8  05:14 /home/netid/osg-photodemo/luminance 3600 200
181587.14  netid           4/8  05:00   0+00:13:40 C   4/8  05:14 /home/netid/osg-photodemo/luminance 2800 200
181587.16  netid           4/8  05:00   0+00:13:39 C   4/8  05:13 /home/netid/osg-photodemo/luminance 3200 200
181587.15  netid           4/8  05:00   0+00:13:29 C   4/8  05:13 /home/netid/osg-photodemo/luminance 3000 200
181587.2   netid           4/8  05:00   0+00:13:21 C   4/8  05:13 /home/netid/osg-photodemo/luminance 400 200
181587.12  netid           4/8  05:00   0+00:13:14 C   4/8  05:13 /home/netid/osg-photodemo/luminance 2400 200
181587.8   netid           4/8  05:00   0+00:12:57 C   4/8  05:13 /home/netid/osg-photodemo/luminance 1600 200
181587.6   netid           4/8  05:00   0+00:12:43 C   4/8  05:13 /home/netid/osg-photodemo/luminance 1200 200
181587.3   netid           4/8  05:00   0+00:12:42 C   4/8  05:13 /home/netid/osg-photodemo/luminance 600 200
181587.5   netid           4/8  05:00   0+00:12:41 C   4/8  05:13 /home/netid/osg-photodemo/luminance 1000 200
181587.4   netid           4/8  05:00   0+00:12:39 C   4/8  05:12 /home/netid/osg-photodemo/luminance 800 200
181587.26  netid           4/8  05:00   0+00:10:57 C   4/8  05:11 /home/netid/osg-photodemo/luminance 5200 200
181587.25  netid           4/8  05:00   0+00:10:51 C   4/8  05:11 /home/netid/osg-photodemo/luminance 5000 200
181587.21  netid           4/8  05:00   0+00:10:41 C   4/8  05:11 /home/netid/osg-photodemo/luminance 4200 200
181587.24  netid           4/8  05:00   0+00:10:40 C   4/8  05:11 /home/netid/osg-photodemo/luminance 4800 200
181587.22  netid           4/8  05:00   0+00:10:39 C   4/8  05:10 /home/netid/osg-photodemo/luminance 4400 200
181587.20  netid           4/8  05:00   0+00:10:37 C   4/8  05:10 /home/netid/osg-photodemo/luminance 4000 200
181587.23  netid           4/8  05:00   0+00:10:33 C   4/8  05:10 /home/netid/osg-photodemo/luminance 4600 200
181587.27  netid           4/8  05:00   0+00:09:21 C   4/8  05:09 /home/netid/osg-photodemo/luminance 5400 200
```

You can see much more information about your job's final status using the -long option.

##### Check the job output

Once your job has finished, you can look at the files that HTCondor has returned to the working directory. If everything was successful, it should have returned:

  +a log file from Condor for the job cluster: job.log
  +an output file for each job's output: log/job.output.*
  +an error file for each job's errors: log/job.error.*

##### Where did jobs run?

It is interesting and sometimes useful to see where on the grid your jobs are running. Two connect commands are useful for this. connect histogram displays a distribution of resources in use by your current jobs – it is analogous to condor_q. connect historygram shows the same information for past jobs, based on condor_history.
 
```
$ connect historygram 181587
Val          |Ct (Pct)     Histogram
amazonaws.com|28 (100.00%) ████████████████████████████████████████████████████▏
```
In this instance, all jobs ran in the Amazon cloud, where a few nodes are provisioned for this tutorial session.
```
$ connect historygram 181590
Val          |Ct (Pct)    Histogram
amazonaws.com|30 (53.57%) █████████████████████████████████████████████████████▏
unl.edu      |20 (35.71%) ███████████████████████████████████▍
ucdavis.edu  |2 (3.57%)   ███▋
mwt2.org     |2 (3.57%)   ███▋
cinvestav.mx |1 (1.79%)   █▉
vt.edu       |1 (1.79%)   █▉
```
 
In this later run, more jobs were submitted than Amazon had space for, so jobs also went out to UC Davis, Midwest Tier 2, UNL, and others.

(See our other tutorials for more details on job analysis options.)
 
##### Gather outputs and plot the aggregated results

This job cluster has illustrated that jobs may grab files on demand via HTTP from Stash. Stash is also useful for quick result aggregation. As an example, try the following:
```
$ cat scatter_pre.html log/job.output.* scatter_post.html >$HOME/stash/public/scatter.html
```
 
Recall that this job writes results in JavaScript/JSON format. The scatter_pre.html and scatter_post.html files are designed to "wrap" those results, which may appear in any order since they're just unordered data points. This command is a really easy way to collect results into a usable file. Since $HOME/stash/public is exposed via HTTP, you may view the resulting plot directly at http://stash.osgconnect.net/+netid/scatter.html . Try clicking that link (which will give an error), then editing netid to your own username. View the HTML source if you like – you'll see how the job output was wrapped into the HTML sandwich, and find mildly interesting tidbits about job destinations and performance.
