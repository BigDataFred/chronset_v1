 CHRONSET INSTALLATION
#
# LINUX users
# -----------
# If you are using a Linux based OS, the default installation is to place the chronset folder into the /usr/local/ directory.
#
# WINDOWS users
# -------------
# If you are using Windows as your OS, the default installation is to place the chronset folder into the C:\Program Files directory.


COMPILING YOUR OWN VERSION:


To compile the standalone for chronset:


A pre-processed list of bundle files is available in m.bundle.txt.  If you receive errors below, you may need to rebuild the bundle.
Instructions to do so follow.

First, ensure that the bundle is up to date by running create__bundle.sh.
--you may need to trim out the make_linux.m, clean.m, and one version of wavread2.m (it does not matter which).
--you may also ned to remove some of the monte carlo simulation functions for
--computing t-tests, which are irrelevant to the batch file execution.

Second, run make_linux64.m in MATLAB

Once the application is compiled, you can run it with:

./run_chronset_batch.sh /opt/matlab/MATLAB_Compiler_Runtime/v80/ ~/barmstrong/Chronset_input/  ~/output.txt

Updating the location of the wav files, output file, and MCR as appropriate.


RUNNING AS BATCH JOB:

If you are running on your local machine and have configured the pathing correctly, you should be able to run a command like the following to process a batch of files:

chronset_batch('./DIR_CONTAINING_ONLY_WAVS/', './OUTPUTOFCHRONSET.txt')
