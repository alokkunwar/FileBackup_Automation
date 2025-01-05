#!/bin/bash

# Creating all the global variables that are going to be used by the program
ParentDirectory="/home/kunwar2"
ParentBackupLocation="$ParentDirectory/backup"
FileExtensions=""
CurrentParentDirectoryForBackup=""
CurrentSubDirectoryForBackup=""
LocationForCompleteBackup="$ParentBackupLocation/cbup24s"
logFile="$ParentBackupLocation/backup.log"
LocationForIncrementalBackup="$ParentBackupLocation/ibup24s"
LocationForDifferentialBackup="$ParentBackupLocation/dbup24s"


# method to remove the directory
function clearDirectory() {
     local directoryToRemove="$1"
     rm -rf "$directoryToRemove"
}

#Method to create directory
function createDirectory() {
     local directoryToCreate="$1"
     mkdir -p "$directoryToCreate"
}

#Method to create log file
function createLogFile() {
     local logFileToCreate="$1"
     touch "$logFileToCreate"
}

#Time for which process is going to sleep
pauseTime=120

# Running the sleep command to make the process sleep
function pauseTheProcess() {
     local timetoPause="$1"
     sleep "$timetoPause"
}

#Method returning the complete path of the latest file created in the given folder
function retriveTheLatestFile() {
    local providedDirectory="$1"
    echo "$providedDirectory/$(ls -t "$providedDirectory" | head -n1 2>/dev/null)"
}

# Method used to set the global variable to get the latest tar file created in the given folder
function setLatestFileToBackup() {
    # defining some local variable to set the global variable

    #typeOfBackup is used to distinguish between the Complete, incremental and differential backup.
    local typeOfBackup="$1"
    #dirToBackup is used to set the Directory Path of Complete, incremental and differential backup.
    local dirToBackup="$2"

    #fileToBackup is used to set the tar file name created for the Complete, incremental and differential backup.
    local fileToBackup="$3"

    if [ "$typeOfBackup" -eq 1 ]; then
        #If it is 1 then it set the variable lastFileToBackupUsingComplete to a concatenated string formed by combining the variable dirToBackup and fileToBackup.
        lastFileToBackupUsingComplete="$dirToBackup/$fileToBackup"
    elif [ "$typeOfBackup" -eq 2 ]; then
        lastFileToBackupUsingIncremental="$dirToBackup/$fileToBackup"
    elif [ "$typeOfBackup" -eq 3 ]; then
        lastFileToBackupUsingDifferential="$dirToBackup/$fileToBackup"
    fi
}

#Method to show the general message to the console
function printGeneralMessage() {
    local generalMessage="$1"
    echo "$generalMessage"
}

#Mehod to prepare the log for sucessful operation and redirect it to the log file
function printSucessfullMessage() {
    local createFile="$1"
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $createFile was created" >> "$logFile"
}

#Mehod to prepare the log for un-sucessful operation and redirect it to the log file
function printErrorMessage() {
    local BackupType="$1"
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - $BackupType backup was not created." >> "$logFile"
}

#Method to create tar file.
function createTARFile() {
    local destinationDirectory="$1"
    local destinationFile="$2"
    local sourceDirectory="$3"
    #Make the tar file from sourceDirectory to destinationDirectory for the file destinationFile
    tar -cf "$destinationDirectory/$destinationFile" $sourceDirectory >/dev/null 2>&1
}

#Method to prepare the TAR file name
function createTARFileName() {
    local tarFilePrefix="$1"
    local tarFileName="$2"
    echo "$tarFilePrefix-$tarFileName.tar"
}

# Preparing the command to search the files 
function prepareSearch() {
    # searchCommand is used to store the Command that is being passed by the caller method
    local searchCommand="$1"
    #FileExtensions stores the list of extension being passed by the caller method
    if [ ${#FileExtensions[@]} -gt 0 ]; then
        # Iterating over all the proveided extension
        for extension in "${FileExtensions[@]}"; do
            #Concateniting -name '*$extension' -o in the proveded search command
            searchCommand="$searchCommand -name '*$extension' -o"
        done
        searchCommand="${searchCommand% -o}" 
    fi
    #returning the value
    echo "$searchCommand" 
}

#Method to perform Differential Backup
function performDifferentialBackup() {
    #CurrentParentDirectoryForBackup and CurrentSubDirectoryForBackup to get the next backup number
    CurrentParentDirectoryForBackup="$LocationForDifferentialBackup"
    CurrentSubDirectoryForBackup="dbup24s"
    #Calling the method calculateTheFileOccurance to get the backup number
    local backupNumber=$(calculateTheFileOccurance)
    #Calling the method to get the new tar file name.
    local fileToCreate=$(createTARFileName "dbup24s" "$backupNumber") 

    local backupType=3
    local backupTypeShortName="Differential"

    local filesForDifferentialBackup=$(find "$ParentDirectory" -type f -not -path "$ParentBackupLocation/*" -newer "$lastFileToBackupUsingComplete" 2>/dev/null)

    if [ -n "$filesForDifferentialBackup" ]; then
        #Calling the method to create tar file.
        createTARFile "$LocationForDifferentialBackup" "$fileToCreate" "$filesForDifferentialBackup"
        # Calling the method to log sucessful message in the log file.
        printSucessfullMessage "$fileToCreate"
        # Calling method to store the latest file created in the Differential backup location
        setLatestFileToBackup "$backupType" "$LocationForDifferentialBackup" "$fileToCreate"
    else
        #Calling the method to print the error message
        printErrorMessage "$backupTypeShortName"
    fi
}    

function performIncrementalBackup() {
    #CurrentParentDirectoryForBackup and CurrentSubDirectoryForBackup to get the next backup number
    CurrentParentDirectoryForBackup="$LocationForIncrementalBackup"
    CurrentSubDirectoryForBackup="ibup24s"
    #Calling the method calculateTheFileOccurance to get the backup number
    local backupNumber=$(calculateTheFileOccurance)
    #Calling the method to get the new tar file name.
    local fileToCreate=$(createTARFileName "ibup24s" "$backupNumber") 

    local backupType=2
    local backupTypeShortName="Incremental"
    FileExtensions=("$@")

    local referenceFile="$lastFileToBackupUsingComplete"
    if [ -n "$lastFileToBackupUsingIncremental" ]; then
        referenceFile="$lastFileToBackupUsingIncremental"
    fi
    # Defining the find command for the Incremental backup
    local findCommand="find $ParentDirectory -type f -not -path '$ParentBackupLocation/*'"
    if [ -n "$referenceFile" ]; then
        findCommand="$findCommand -newer $referenceFile"
    fi
    # Preparing the search command for the Incremental backup
    findCommand=$(prepareSearch "$findCommand") 

    #Result after running the find command
    local filesForIncrementalBackup=$(eval "$findCommand")

    if [ -n "$filesForIncrementalBackup" ]; then
         #Calling the method to create tar file.
        createTARFile "$LocationForIncrementalBackup" "$fileToCreate" "$filesForIncrementalBackup"
        #Calling the method to print sucessful message in the log file
        printSucessfullMessage "$fileToCreate"
        #Setting the latest file that is being backuped
        setLatestFileToBackup "$backupType" "$LocationForIncrementalBackup" "$fileToCreate"
    else
        # log the error message
        printErrorMessage "$backupTypeShortName"
    fi  
}

function performCompleteBackup() {
    CurrentParentDirectoryForBackup="$LocationForCompleteBackup"
    CurrentSubDirectoryForBackup="cbup24s"
    # Get the Backup number
    local backupNumber=$(calculateTheFileOccurance)
    # Converting the extensions into an array and storing it in global var for processing
    FileExtensions=("$@")
    local backupType=1
    #get the tar file
    local fileToCreate=$(createTARFileName "cbup24s" "$backupNumber")
    # Preparing the find command to search the files
    local findCommand="find $ParentDirectory -type f"
    findCommand=$(prepareSearch "$findCommand") 

    #Executing the command 
    eval "$findCommand" | tar -cf "$LocationForCompleteBackup/$fileToCreate" -T - >/dev/null 2>&1
    #Loging the sucessful message in the log file
    printSucessfullMessage "$fileToCreate"
    #Setting the latest file backed up
    setLatestFileToBackup "$backupType" "$LocationForCompleteBackup" "$fileToCreate"
}

# Method to validate the list of arguments provided by the user
if [ "$#" -gt 3 ]; then
    printGeneralMessage "You have given more than three file types. Please enter upto three file type or no file type."
    exit 0
fi

# Method to get the next unused backup number
function calculateTheFileOccurance() {
    #Counter to prepare the used backup nuymber
    local counter=1
    while true; do
        # Preparing the full path name of the tar file and checking it is exist. If not then return the counter value
        if [ ! -f "$CurrentParentDirectoryForBackup/$CurrentSubDirectoryForBackup-$counter.tar" ]; then
            break
        fi
        ((counter++))
    done
    #Returing the value
    echo "$counter"
}

# Calling the method to remove the provided directory
clearDirectory "$ParentBackupLocation"
clearDirectory "$LocationForCompleteBackup"
clearDirectory "$LocationForIncrementalBackup" 
clearDirectory "$LocationForDifferentialBackup" 
clearDirectory "$logFile"

# Calling the method to create the provided directory
createDirectory "$ParentBackupLocation"
createDirectory "$LocationForCompleteBackup"
createDirectory "$LocationForIncrementalBackup" 
createDirectory "$LocationForDifferentialBackup" 

createLogFile "$logFile"

# Setting the latest file backed up for Complete, Incremental and Differential. 
lastFileToBackupUsingComplete=$(retriveTheLatestFile "$LocationForCompleteBackup")
lastFileToBackupUsingIncremental=$(retriveTheLatestFile "$LocationForIncrementalBackup")
lastFileToBackupUsingDifferential=$(retriveTheLatestFile "$LocationForDifferentialBackup")

# calling the metod in the infinite loop
while true; do

    #Caling for complete backup
    performCompleteBackup "$@"
    printGeneralMessage "Complete Backup has been completed."
    #Calling the method to sleep.
    pauseTheProcess "$pauseTime"

    #Caling for Incremental Backup 
    performIncrementalBackup
    printGeneralMessage "Incremental Backup - 1 has been completed."
    #Calling the method to sleep.
    pauseTheProcess "$pauseTime"

    #Caling for Incremental Backup 
    performIncrementalBackup
    printGeneralMessage "Incremental Backup - 2 has been completed."
     #Calling the method to sleep.
    pauseTheProcess "$pauseTime"

    #Caling for Differential Backup 
    performDifferentialBackup
    printGeneralMessage "Differential Backup has been completed."
    #Calling the method to sleep.
    pauseTheProcess "$pauseTime"

    #Caling for Incremental Backup 
    performIncrementalBackup
    printGeneralMessage "Incremental Backup - 3 has been completed."
    #Calling the method to sleep.
    pauseTheProcess "$pauseTime"
done