# hpcc

## Overview
The `hpcc` function is a shell script designed to simplify the process of transferring files between a local directory and a remote directory on the High Performance Computing Cluster (HPCC, now called HPC3). It uses `rsync` to efficiently synchronize data in either direction (pull from or push to HPC3).

## Usage

```
hpcc <command> <name> <subdir>
```

The command has three parameters: 

- `<command>`: Specifies the operation type. It can be either: `"pull"` to transfer files from HPC3 to the local machine or `"push"` to transfer files from the local machine to HPC3.
- `<name>`: Identifies the name of the local and remote directories to be used in the transfer. This name corresponds to predefined environment variables for local and remote directories, which you should define in your `.research_config` file. For example, if `<name>` is `SYMCRT`, then you should have entries in your `.research_config` defining `LOCAL_SYMCRT_DATA_DIR` and `REMOTE_SYMCRT_DATA_DIR`. 
- `<subdir>`: Specifies the subdirectory within the data directories where the transfer will take place.

The command is always executed from your local machine.

## Examples

To transfer the files for the `symcrt` project from your computer to HPC3, run 
```
hpcc push SYMCRT
```
To transfer the files for the `symcrt` project from HPC3 to your computer, run
```
hpcc pull SYMCRT
```

# selectiveMergeInto

## Overview
The `selectiveMergeInto` function is a shell script that facilitates maintaining two branches in a repository for a project, only some files of which will be published:

- The `main` branch contains all of the files for the project.
- The `publish` branch contains just the files that will be eventually published.

The functionality of `selectiveMergeInto` is to merge changes from one Git branch into another, while excluding specific files and directories listed in a `.publishignore` file. Additionally, `selectiveMergeInto` takes care of keeping `renv` up to date during a merge, because `renv.lock` need not be the same on both branches.

## Usage

There are two ways of using the function: 

- To merge the branch `main` into the branch `publish`, start on the `main` branch, commit your changes, and then execute
  ```
  selectiveMergeInto publish
  ```
  You will end up on the `publish` branch at the end of this operation.

- To merge the branch `publish` into the branch `main`, start on the `publish` branch, commmit your changes, and then execute
  ```
  selectiveMergeInto main
  ```
  You will end up on the `main` branch at the end of this operation.

I encourage you not to make changes in both `main` and `publish` branches. Work on one branch at a time. If you want to start working on the other branch, switch to it via `selectiveMergeInto` rather than via `git checkout`.

## Limitations
This script is only designed for environments using Git and R with `renv` library management. It can only be used to merge between branches named `main` and `publish`.
