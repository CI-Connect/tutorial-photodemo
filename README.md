OSG Connect Tutorial: Photo Analysis Demo
=========================================

In this tutorial you will perform a very simple distributed analysis of approximately 5,000 digitized images from a photograph archive that associates an XML metadata file with each photo. This job uses the Python Imaging Library (PIL) to convert each JPEG image into an array of RGB color space tuples, and from them find the average luminance of the entire image. The result of each computation will be a pairing of average luminance with the year that the photo was taken. Jobs will write these results in JavaScript/JSON format, so that the results of all jobs in aggregate can be used to submit raw data into the Google Charts API and produce a straightforward scatter plot.

Goals for this tutorial:

1. use the HTTP file service on Stash to store and retrieve data
2. store results into Stash for quick visualization of results in a web browser
3. create a Python "virtualenv" to distribute custom Python libraries across the grid with your job


Login to OSG Connect
--------------------

  * If not already registered to OSG Connect, go to the [registration site](https://osgconnect.net) and follow instructions there.
  * Once registered, you are authorized to use **login.osgconnect.net** (the Condor submit host) and **stash.osgconnect.net** (the data host), in each case authenticating with your network ID (**netid**) and password:
```
$ ssh netid@login.osgconnect.net
```

Set up the tutorial
-------------------
This tutorial depends on several files that we have set up in advance:

  + **manifest.txt** - a prearranged input file associating the URL of a photo with the year it was taken
  + **luminance2** - a Python program that selects a specified subset of the manifest, downloads the image over HTTP, and uses PIL to compute the image's average luminance
  + **mksubmit** - a shell script to generate a Condor submit file
  + **run.sh** - a job wrapper, written in shell, and
  + **aggregate.sh** - a shell script to aggregate results into a web-based visualization, using
  + **scatter_pre.html** and **scatter_post.html** - HTML snippets that sandwich [year, luminance] tuples to produce a complete HTML file to plot the data using Google Charts.

Because these inputs and programs are not easy to type, the tutorial is available only using the tutorial command. Let's set up the photodemo tutorial:

```
$ tutorial photodemo 
Storage access demonstration using distributed photograph analysis
Tutorial 'photodemo' is set up.  
```
To begin:
```
cd ~/tutorial-photodemo
$ cd ~/tutorial-photodemo 
$ ls
```

Prepare the job environment
---------------------------
The **luminance2** program uses a Python library for image processing known as Pillow -- although the module name to import is _PIL_.  The trouble with this approach is that while PIL is great for processing bitmapped images such as our photo archive, it's not a standard part of Python and you can't expect it to be on any OSG worker nodes.  It's also not available in the OASIS module collection.  This makes it a good candidate for illustrating how to bundle custom modules with a Python job, whether they are developed in-house at your lab or simply are unconventional

The key to Python library bundling is a program called **virtualenv**.  This program is installed on `login.osgconnect.net`.  (We also say "virtualenv" to refer to the bundles, or environments, that the virtualenv tool creates.)

##### Create a virtual environment

Let's create a new virtualenv named `pillow`.  Enter the following command at your `login.osgconnect.net` command prompt:

		# Create the virtualenv
		$ virtualenv pillow

##### Populate the virtualenv with Python code

Now your virtualenv is ready to populate with your custom Python modules. Let's do that.  First we will add the `virtualenv` command itself to the environment, because we'll need it again on each worker node:

		# Find and copy into place the virtualenv software
		$ cp $(python -c 'import virtualenv; print virtualenv.__file__' |
	           sed -e 's/pyc/py/') pillow/bin/
	    $ cp $(which virtualenv) pillow/bin/
	
		# "activate" the virtualenv
		$ source pillow/bin/activate
	
		# Install PIL. The STATIC_DEPS variable uses static libraries for any compiled dependencies
		$ env STATIC_DEPS=true pip install Pillow
	
		# Now "deactivate" the virtualenv
		$ deactivate

##### Bundle the environment

That should complete the virtual environment setup.  Let's create a single-file "tarball" to bundle it for job distribution:

		$ tar cf pillow.tar pillow



Run the job
-----------

##### Test the job locally

When setting up a new job type, it's important to **test your job outside of Condor** before submitting into the grid. Here is what a quick run over five photos would look like when it executes successfully on a worker:

```
$ ./luminance2 results.json 0 5 <manifest.txt 
/* Running on host: login01.osgconnect.net */
[1880, 0.525493],
[1919, 0.416121],
[1919, 0.436667],
[1919, 0.461788],
[1945, 0.142712],
/* 5 photos analyzed in 6.94s (1.39/s) */
```

This works, so we can feel comfortable scaling up.

##### Write a job wrapper to unbundle the virtualenv

Our test worked, but wait -- clearly PIL is installed on `login.osgconnect.net`, but we don't trust that it will be installed anywhere else on the grid.  Indeed if you were to submit this job as above, it would fail spectacularly: probably none of the queued jobs would succeed.  So we need to unbundle that virtualenv we created. To do that we create a job wrapper named `run.sh`.  That file already exists so that you don't need to write it, but let's study it a moment:
```
#!/bin/bash
	
# This is a simple job wrapper to unpack the python virtual environment
# and run the 'luminance2' program, saving output into a results file.
	
# Unpack the pillow.tar virtualenv which was bundled with the job
tar xf pillow.tar
	
# Update it to run on this worker
python pillow/bin/virtualenv.py pillow
	
# Activate the virtualenv to get access to its local modules
source pillow/bin/activate
	
# N.B. It's important to run "python scriptname" here so that we get the
# python interpreter packaged by the virtualenv instead of the one installed
# on the target system.
#
# Use "$@" to pass whatever arguments came into this script.
python luminance2 "$@"
```
This script is the "glue" we need to sequence the unbundling of the virtualenv (`tar`), the reconfiguration of the environment (`python .../virtualenv.py pillow`), the activation of the virtualenv (`source .../activate`) and the execution of the actual code.


##### Create a submit file

When you have one large collection of inputs to distribute over many job slots, you can take either of two approaches:

  * break the input into many smaller inputs, and send a different input to each job instance;
  * send the whole input set with each job, but configure the job to perform its own selection on the input.
     
To optimize performance over many thousands of jobs at slight expense to storage, the first approach is often better. In this tutorial, the inputs are small (only a URL and a year for each photo, and no actual photo data) and are relatively few (~5500). In order to keep file management to a minimum, we will take the second approach. Each enqueued job will take the same input (`manifest.txt`), and its command line arguments will tell it which rows to work on. To produce a submit file with so many differing parameters, we have a shell script that outputs a Condor submit file.
     
Run `mksubmit` to create a submit file. By default each resulting job will analyze 200 photos, so the job cluster uses about 28 slots. You can change the size of the cluster by chunking with a different value.
     
	    # Use 28 slots of 200 photos each
	    $ ./mksubmit 200 >submit.sub
	    # Or use 56 slots of 100 photos each
	    $ ./mksubmit 100 >submit.sub

##### Project Names
Remember that all jobs running in the OSG need to have a project name assigned. To see the projects you belong to, you can use the command connect show-projects:
 
	$ connect show-projects
	Based on your username (dgc), here is a list of projects you have
	access to:
	  * ConnectTrain
	  * OSG-Staff

One of these will be the "default project" that all your jobs run under. You have two ways to use a different project name for your jobs:

  1. Use the `connect project` command to interactively select a different default project for all your work.
  2. Add the +ProjectName="MyProject" line to the HTCondor submit file. **Remember to quote the project name!**

##### Submit the job

Submit the job using condor_submit.
	$ condor_submit submit.sub 
	Submitting job(s)............................
	28 job(s) submitted to cluster 181587.
##### Monitor job status

The condor_q command tells the status of currently running jobs. Generally you will want to limit it to your own jobs by giving it your own username:
```
$ condor_q netid
-- Submitter: login01.osgconnect.net : <192.170.227.195:56133> : login01.osgconnect.net
 ID      OWNER            SUBMITTED     RUN_TIME ST PRI SIZE CMD               
2710704.0   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-0.j
2710704.1   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-200
2710704.2   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-400
2710704.3   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-600
2710704.4   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-800
2710704.5   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-100
2710704.6   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-120
2710704.7   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-140
2710704.8   netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-160
2710704.9   netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-180
2710704.10  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-200
2710704.11  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-220
2710704.12  netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-240
2710704.13  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-260
2710704.14  netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-280
2710704.15  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-300
2710704.16  netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-320
2710704.17  netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-340
2710704.18  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-360
2710704.19  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-380
2710704.20  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-400
2710704.21  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-420
2710704.22  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-440
2710704.23  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-460
2710704.24  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-480
2710704.25  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-500
2710704.26  netid           3/5  14:13   0+00:01:47 R  0   0.0  run.sh results-520
2710704.27  netid           3/5  14:13   0+00:00:00 I  0   0.0  run.sh results-540

28 jobs; 0 completed, 0 removed, 22 idle, 6 running, 0 held, 0 suspended
```	

If you want to see all jobs running on the system, use condor_q without any extra parameters.

Note the ST (state) column. Your job will be in the **I** state (idle) if it hasn't started yet. If it's currently scheduled and running, it will have state **R** (running). If it has completed already, it will not appear in `condor_q`.

Let's wait for your job to finish – that is, for `condor_q` not to show the job in its output. The `connect watch` command will give you semi-realtime updates on job status. Try it now. Press **control-C** to stop watching.

##### A bit about Stash

While waiting for jobs to complete, let's look a little more closely at what we've done. Take a peek at the **manifest.txt** file:
 
	$ head -1 manifest.txt
	http://stash.osgconnect.net/@ConnectTrain/photodemo/ucpa/series1/derivatives_series1/apf1-00001r.jpg 1880
 
Notice the format of the URL. Each project in OSG Connect has a space in Stash that is visible over HTTP. You can see it on the login node at /stash/projects/@<projectname>/public. (Above the public directory is private space for the project. Private space is not visible on the web, and you may set permissions to hide it from other OSG Connect users as well.)

If you paste a URL from the manifest file into your browser, you'll see the photograph.  Stash is an important piece of the OSG Connect ecosystem; it makes your data available anywhere that your jobs run. Stash HTTP meshes nicely with Condor's native ability to transfer input from HTTP URLs, and if a worker endpoint uses an $http_proxy it will naturally see locality benefits.
 
Take a break while this job completes. Depending on the target resource, it can take anywhere from 3 minutes to 15 to run even when resources are immediately available.
 
Assess results
--------------
 
##### Job history

Once your job has finished, you can get information about its execution from the condor_history command:
```
$ condor_history 2710704
ID     OWNER          SUBMITTED   RUN_TIME     ST COMPLETED   CMD            
2710704.9   netid           3/5  14:13   0+00:03:15 C   3/5  14:18 /home/netid/tutorial-photodemo/run
2710704.17  netid           3/5  14:13   0+00:03:06 C   3/5  14:18 /home/netid/tutorial-photodemo/run
2710704.16  netid           3/5  14:13   0+00:03:02 C   3/5  14:18 /home/netid/tutorial-photodemo/run
2710704.12  netid           3/5  14:13   0+00:02:57 C   3/5  14:18 /home/netid/tutorial-photodemo/run
2710704.14  netid           3/5  14:13   0+00:02:57 C   3/5  14:18 /home/netid/tutorial-photodemo/run
2710704.26  netid           3/5  14:13   0+00:02:23 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.18  netid           3/5  14:13   0+00:01:41 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.24  netid           3/5  14:13   0+00:01:41 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.23  netid           3/5  14:13   0+00:01:39 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.19  netid           3/5  14:13   0+00:01:38 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.27  netid           3/5  14:13   0+00:00:44 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.22  netid           3/5  14:13   0+00:01:37 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.5   netid           3/5  14:13   0+00:01:36 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.1   netid           3/5  14:13   0+00:00:46 C   3/5  14:17 /home/netid/tutorial-photodemo/run
2710704.3   netid           3/5  14:13   0+00:01:21 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.11  netid           3/5  14:13   0+00:01:30 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.0   netid           3/5  14:13   0+00:00:43 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.2   netid           3/5  14:13   0+00:00:41 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.8   netid           3/5  14:13   0+00:01:13 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.21  netid           3/5  14:13   0+00:01:12 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.6   netid           3/5  14:13   0+00:01:08 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.25  netid           3/5  14:13   0+00:00:13 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.4   netid           3/5  14:13   0+00:00:53 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.13  netid           3/5  14:13   0+00:00:51 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.15  netid           3/5  14:13   0+00:00:50 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.7   netid           3/5  14:13   0+00:00:47 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.20  netid           3/5  14:13   0+00:00:46 C   3/5  14:16 /home/netid/tutorial-photodemo/run
2710704.10  netid           3/5  14:13   0+00:00:46 C   3/5  14:16 /home/netid/tutorial-photodemo/run
```

You can see much more information about your job's final status using the -long option.

##### Check the job output

Once your job has finished, you can look at the files that HTCondor has returned to the working directory. If everything was successful, it should have returned:

  + a log file from Condor for the job cluster: job.log
  + an output file for each job's output: log/job.output.*
  + an error file for each job's errors: log/job.error.*
  + a `results-###.json` file for each job.

##### Where did jobs run?

It is interesting and sometimes useful to see where on the grid your jobs are running. Two `connect` commands are useful for this. `connect histogram` displays a distribution of resources in use by your current jobs – it is analogous to `condor_q`. `connect histogram --last` shows the same information for your previous job cluster, based on `condor_history`.
 
 ```
$ connect histogram --last
Val          |Ct (Pct)     Histogram
amazonaws.com|28 (100.00%) ████████████████████████████████████████████████████▏
```
In this instance, all jobs ran in the Amazon cloud, where a few nodes are provisioned for this tutorial session.
```
$ connect historygram --last
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
	$ ./aggregate.sh >$HOME/stash/public/scatter.html
 
Recall that this job writes results in JavaScript/JSON format. The scatter_pre.html and scatter_post.html files are designed to "wrap" those results, which may appear in any order since they're just unordered data points. This command is a really easy way to collect results into a usable file. Since $HOME/stash/public is exposed via HTTP, you may view the resulting plot directly at http://stash.osgconnect.net/+netid/scatter.html . Try clicking that link (which will give an error), then editing netid to your own username. View the HTML source if you like – you'll see how the job output was wrapped into the HTML sandwich, and find mildly interesting tidbits about job destinations and performance.

## Getting Help
For assistance or questions, please email the OSG User Support team  at `user-support@opensciencegrid.org`, send a direct message via your twitter account to [@osgusers](http://twitter.com/osgusers), or visit the [help desk and community forums](http://support.opensciencegrid.org).
