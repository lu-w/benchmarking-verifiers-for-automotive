# Benchmarking Software Model Checkers on Automotive Code

Contains the benchmarking scripts used for the paper "Benchmarking Software Model Checkers on Automotive Code", to be published in ATVA 2019.

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
