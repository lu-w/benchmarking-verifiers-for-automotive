# Benchmarking Software Model Checkers on Automotive Code

Contains the benchmarking scripts used for the paper "Benchmarking Software Model Checkers on Automotive Code", to be published in ATVA 2019. This tool is specialized to our specific use case and most likely won't generalize well into other environments.

## Structure

`benchmark.sh` is the main benchmark script entry point.

`benchmark_core.sh` contains the core functionality of the benchmarking process.

`benchmark_output_interpretation.sh` outsources the output interpretation as it is rather lengthy.

## Dependencies

The benchmark script has some dependencies.
* `timeout` https://github.com/pshved/timeout (expected in `$PATH`)
* `/usr/bin/time`
* `mailx` if mail notifications are enabled

## Example usage

To benchmark [CBMC](https://github.com/diffblue/cbmc) on all C files in `input_dir`, with a timelimit of one minute and a memory limit of one GB:

`./benchmark.sh -t 1 -m 1 -c "cbmc" -i input_dir`

Note that the CBMC binary should be in `$PATH`. Results will be written to `./cbmc_1GB_1m.csv`. Outputs (verification run logs, witnesses) can be found in `benchmark_output`.

## Help

Performs a batch execution of a given command, where the command is called on each file in the given input folder. The results of the benchmark are written to a .csv file in the output folder, named after the given command and environment
parameters. The command can either be given directly as a string or, if a file exists that matches the command parameter, the command string is taken from the contents of the file. In this string, you can access the variables MEMORY (GB) and TIME (s) to give additional hints to the benchmarked tool. It allows to set a memory and CPU time limit for each run that is executed. The script automatically calculates the number of runs that it can execute parallely w.r.t. the given limits. It splits the available number of CPU cores fairly amongst the parallel runs.

```
Usage: benchmark.sh
-c command    Either a command name to execute, excluding the file option, or a file containing mentioned command.
-i folder     Input folder containing the specification files.
[-o folder]   Output folder to write the resulting csv to. Defaults to the current folder.
[-t number]   Time limit for each run, in minutes. Defaults to 120 m.
[-m number]   Memory limit for each run, in gigabytes. Defaults to 18 GB.
[-a address]  Sends start and finish notifications to the given mail address.
```
