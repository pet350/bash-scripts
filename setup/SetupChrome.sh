#!/bin/bash

# Adding Chrome repo
# The first step is adding the Google Chrome repo. Fire up a terminal and run the following command.
zypper ar http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome


# In the command, “ar” stands for “addrepo”. To learn more about Zypper and its usage, check out how to use Zypper on openSUSE.
# The repo isn’t ready to use yet. We need to add the Google public signing key so that the packages can be verified. Run these commands.
wget https://dl.google.com/linux/linux_signing_key.pub
rpm --import linux_signing_key.pub


# Once importing the key is complete, update the repo cache of zypper.
zypper ref -f


#Installing Chrome
#Finally, zypper is ready to grab Google Chrome from the repo!
zypper in google-chrome-stable


# If you’re looking for other Google Chrome builds like beta or unstable, run the following command(s).
#zypper in google-chrome-beta
#zypper in google-chrome-unstable


