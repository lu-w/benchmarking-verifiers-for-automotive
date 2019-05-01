#!/bin/bash

source ./benchmark_core.sh

function show_help {
	echo "Performs a batch execution of a given command, where the command is called on
each file in the given input folder. The results of the benchmark are written to
a .csv file in the output folder, named after the given command and environment
parameters. The command can either be given directly as a string or, if a file
exists that matches the command parameter, the command string is taken from the
contents of the file. In this string, you can access the variables
MEMORY (GB) and TIME (s) to give additional hints to the benchmarked tool.
It allows to set a memory and CPU time limit for each run that is executed. The
script automatically calculates the number of runs that it can execute parallely
w.r.t. the given limits. It splits the available number of CPU cores fairly
amongst the parallel runs.

Usage: benchmark.sh
-c command	Either a command name to execute, excluding the file option, or
		a file containing mentioned command.
-i folder	Input folder containing the specification files.
[-o folder]	Output folder to write the resulting csv to. Defaults to the
		current folder.
[-t number]	Time limit for each run, in minutes. Defaults to 120 m.
[-m number]	Memory limit for each run, in gigabytes. Defaults to 18 GB.
[-a address]	Sends start and finish notifications to the given mail address.
[-h]		Shows this help message."
}

input=""
call_string=""
output="."
optstring="hi:o:c:t:m:a:"

# Process time and memory constraints first, as they may be needed for replacement later on.
while getopts $optstring opt; do
	case "$opt" in
	t)
		TIME_PER_CALL=$OPTARG
		;;
	m)
		MEMORY_PER_CALL=$OPTARG
		;;
	esac
done
OPTIND=1
while getopts $optstring opt; do
	case "$opt" in
	h|\?)
		show_help
		exit 0
		;;
	i)
		input=$OPTARG
		;;
	c)
		if [ -f "$OPTARG" ]; then
			call_string=$(MEMORY=$(( $MEMORY_PER_CALL )) TIME=$TIME_PER_CALL envsubst < "$OPTARG")
		else
			call_string=$(echo "$OPTARG" | MEMORY=$MEMORY_PER_CALL TIME=$TIME_PER_CALL envsubst)
		fi
		;;
	o)
		output=$OPTARG
		;;
	a)
		MAIL_ADDRESS=$OPTARG
		SEND_MAIL_STARTED=true
		SEND_MAIL_FINISHED=true
		;;
	esac
done
shift $(($OPTIND - 1))

if [ "$input" = "" ]; then echo "No input folder given!"; show_help; exit 1; fi
if [ "$call_string" = "" ]; then echo "No command name given!"; show_help; exit 1; fi
if [[ $MAX_MEMORY -lt $MEMORY_PER_CALL ]]; then echo "Too little memory available!"; exit 1; fi

# Right now, using SV comp definitions of time and memory for witness validations.
MEMORY_PER_COUNTEREXAMPLE_VALIDATION=$MEMORY_PER_CALL
MEMORY_PER_PROOF_VALIDATION=$MEMORY_PER_CALL
TIME_PER_COUNTEREXAMPLE_VALIDATION=$((TIME_PER_CALL / 10))
TIME_PER_PROOF_VALIDATION=$TIME_PER_CALL

# The maximum number of parallel processes and cores according to the runtime constants.
MAX_PARALLEL_PROCESSES=$(( MAX_MEMORY / MEMORY_PER_CALL < MAX_CORES ? MAX_MEMORY / MEMORY_PER_CALL : MAX_CORES ))
CORES_PER_PROCESS=$(( MAX_CORES / MAX_PARALLEL_PROCESSES ))

echo "[$(uname -n)] Benchmarking $(determine_verifier_config_combination "$call_string") on $input"
echo ""

env_vars="Environment variables:
Parallel jobs:					$MAX_PARALLEL_PROCESSES
Available CPU cores:				$MAX_CORES
Available memory:				$MAX_MEMORY GB
Maximum CPU cores per job:			$CORES_PER_PROCESS
Maximum memory per job:				$MEMORY_PER_CALL GB
Maximum time per job:				$TIME_PER_CALL m
Maximum memory per proof validation:		$MEMORY_PER_PROOF_VALIDATION GB
Maximum time per proof validation:		$TIME_PER_PROOF_VALIDATION m
Maximum memory per counterexample validation:	$MEMORY_PER_COUNTEREXAMPLE_VALIDATION GB
Maximum time per counterexample validation:	$TIME_PER_COUNTEREXAMPLE_VALIDATION m"
echo "$env_vars"

input_subfolders=$(echo "$input" | cut -d / -f 2-)
verifier_folder_name=$(determine_verifier "$call_string" | tr '[:upper:]' '[:lower:]' | tr -d -)
WITNESS_FOLDER="benchmark_output/$input_subfolders/$verifier_folder_name/witnesses"
VERIFIER_OUTPUT_FOLDER="benchmark_output/$input_subfolders/$verifier_folder_name/runs"

# Creates output folders if necessary.
mkdir -p "$WITNESS_FOLDER"
mkdir -p "$VERIFIER_OUTPUT_FOLDER"
WITNESS_FOLDER=$(realpath "$WITNESS_FOLDER")
VERIFIER_OUTPUT_FOLDER=$(realpath "$VERIFIER_OUTPUT_FOLDER")

# Sends start mail.
if [ "$SEND_MAIL_STARTED" = true ]
then
	echo "$env_vars" | mailx -s "[$(uname -n)] Started $(determine_verifier_config_combination "$call_string") on $input" "$MAIL_ADDRESS"
fi

# Starts batch execution, logs into log file to be able to send log later on.
log_file=$(mktemp)
run_batch "$call_string" "$input" "$output" | tee "$log_file"

# Sends finish mail. Sleeps 10 seconds due to a weird bug on our nodes where mails wouldn't be sent.
if [ "$SEND_MAIL_FINISHED" = true ]
then
	cat "$log_file" | mailx -s "[$(uname -n)] Finished $(determine_verifier_config_combination "$call_string") on $input" "$MAIL_ADDRESS"
	sleep 10s
fi