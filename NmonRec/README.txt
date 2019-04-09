# Before to use Start and Stop Nmon make sure :
# All the linux must have an authorized ssh-key from the server that 
# will start the monitoring ex:
# for all the Linux : #ssh-keygen -t rsa -b 1024
# Then :  # cd /root/.ssh
          # ssh-copy-id -i id_rsa.pub root@<local host>
          # ssh-copy-id -i id_rsa.pub root@<remote host >
 
# After that make sure than you can connect from the Nmon server 
# to itself and the others without password .

# As well start the atd daemon on all the server :
       # ex:   # chkconfig -s atd on   
               # chkconfig atd 

# Modify the file "machines"
# It contains the server Linux to monitor .

# Modify the directory name in which will be stored the nmon result files, in this example it is :
#
#  /NmonRec/TEST/.... you can repalce "TEST" by your bencmark name
# 
# Then you have to modify the RUN_NAME value by your benchmark name in the run_variables file  

# The nmon file corresponding to your linux version must be copoied in all
# Servers in /usr/bin .

# THIS NEW VERSION OF NMONREC ALLOWS TO USE SYSSTAT MONITORING
# TO MONITOR THE PID ACTIVITY AND THE IO AND VM STATS ACTIVITY 
# TO USE THIS FUNCTIONALITY IT IS REQUIRED TO INSTALL THE SYSSTAT8.0.4 PACKAGE
# For linux Redhat please install the package sysstat-8.0.4-7.fc11.s390x.rpm
#    rpm -Uvh sysstat-8.0.4-7.fc11.s390x.rpm
# For linux SLES please install the package sysstat-8.0.4.tar.gz
#				tar zxf sysstat-8.0.4.tar.gz
#				cd sysstat-8.0.4
#				./configure
#				./make
#				./make install
#
# To finish active the nmon systat functionality in the run_variables file by changing the flag USE_SYSSTAT from "N" to "Y"
#
# In any case if you choose to use the sysstat functionality the iostat and vmstat activity will be recorded. But
# you will be able to choose, for each run and for each machine, if you want to record or not the pid activity. 
# If yes, you will be asked to type the list of pids to monitor for each machine.
# If you want to monitor the pid activity for each run with always the same pid list, you can set in the run_variables file
# the flag PIDFILE from "N" to "Y". The pid list will be asked once and stored in the <Hostname>.PID file on each machine.
# You can modify this file to add, modify or delete pids to monitor. 
#


# THIS NEW VERSION OF NMONREC ALLOWS TO START PERFKIT VM MONITORING TO MONITOR 
# THE VM ACTIVITY AND GET THE RESULTS .CSV FILES IN YOUR RESULTS DIRECTORY
#
#
# On the VM Machine: 
#
# if you don't have activated the PERFSVM product on your VM, logon to maint and
# issue the following command:
#   service perfkt enable
#
#
# TO ACTIVATE THE PERFKIT MONITORING FUNCTION ON YOUR NMON FIRST CREATE ON YOUR VM A CMS MACHINE CALLED CSVGEN
# WITH THE FOLLOWING USER DEFINITION:
#
# USER CSVGEN CSVPASSWD 32M 32M G                                         
#   CPU 00 BASE                                                        
#   IPL CMS PARM AUTOCR                                                
#   MACHINE ESA 1                                                      
#   OPTION LNKNOPAS                                                    
#   SCR INA WHI NON STATA RED NON CPOUT YEL NON VMOUT GRE NON INRED TUR
#   CONSOLE 0009 3215 T                                                
#   SPOOL 000C 2540 READER *                                           
#   SPOOL 000D 2540 PUNCH A                                            
#   SPOOL 000E 1403 A                                                  
#   LINK MAINT 0190 0190 RR                                            
#   LINK MAINT 019D 019D RR                                            
#   LINK MAINT 019E 019E RR                                            
#   MDISK 0191 3390 101 100 <MYDISK> MR
#
# Find a Disk with 100 cylinders availables, format this disk and replace the <MYDISK> statment 
# by the name of your physical disk
#
# Then if you don't have the VMARC MODULE installed, upload it to the 191 minidisk of CSVGEN by ftp in binary mode.
# Logon to the VM with CSVGEN user and then type following command:
#   PIPE < VMARC MODULE A | deblock cms | > VMARC MODULE A

# Upload the CSVGEN VMARC package to the 191 minidisk of CSVGEN by ftp in binary mode
# Logon to the VM with CSVGEN user and convert the CSVGEN VMARC file to the CMS VMARC format by issuing the following command:
#   PIPE < CSVGEN VMARC A | FBLOCK 80 00 | > CSVGEN VMARC A F 80
# Unpack and expand the CSVGEN VMARC file by issuing the following command:
#   VMARC UNPK CSVGEN VMARC A
# Logoff the session
#
# For the guests linux on which you will start the nmonRec application, you have to modify the user direct by adding classes A and C as in the following example:
#  USER XXXXXX XXXXXX 2G 2G ACG 
#
#
# On the linux machine:
#
# You will have to modify the value of VMSERVERIP by the IP address of your VM 
# To finish, activate the nmon perfkit functionality in the run_variables file by changing the flag USE_PERFKIT from "N" to "Y"
  














                                   
