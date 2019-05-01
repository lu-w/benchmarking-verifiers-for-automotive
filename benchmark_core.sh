#!/bin/bash

###############################################################################
# Includes                                                                    #
###############################################################################

source ./benchmark_output_interpretation.sh

###############################################################################
# Global variables                                                            #
###############################################################################

MAIL_ADDRESS="test@example.com"
SEND_MAIL_STARTED=false
SEND_MAIL_FINISHED=false
# Folders where the verification runs and witnesses outputs are stored.
VERIFIER_OUTPUT_FOLDER=""
WITNESS_FOLDER=""
# Environment constants
MAX_CORES=$(nproc)
MAX_MEMORY=$(( $(cat /proc/meminfo | grep MemFree | tr -dc '0-9') / 1000000 )) # GB
# Runtime constants for each call, can also be set by the user
MEMORY_PER_CALL=18 # GB
TIME_PER_CALL=120 # m
# Runtime constants for each verification witness validation, will be set
# again later, dependent on the user's input of call time and memory.
MEMORY_PER_PROOF_VALIDATION=18 # GB
TIME_PER_PROOF_VALIDATION=120 # m
MEMORY_PER_COUNTEREXAMPLE_VALIDATION=18 # GB
TIME_PER_COUNTEREXAMPLE_VALIDATION=12 # m
# Verifier names
CPACHECKER="CPAChecker"
PESCO="PeSCo"
ULTIMATE="UltimateAutomizer"
ULTIMATEKOJAK="UltimateKojak"
ULTIMATETAIPAN="UltimateTaipan"
SMACK="SMACK"
CBMC="CBMC"
ESBMC="ESBMC"
TWOLS="2LS"
SYMBIOTIC="Symbiotic"
DEPTHK="DepthK"
KINDUCTION="k-Induction"
# An array indicating whether a core is unused (0) or assigned to a job (JOBID)
CPU_CORE_TO_JOBID=()

###############################################################################
# Verification run execution, call assembly, and helper functions             #
###############################################################################

# Executes the given command. The core of the benchmarking process: Here, the
# verification runs are actually started.
# Also performs witness validation after the verification run.
# Writes the following contents to its given output file:
# The program output
# The time -v output
# $1: Program call string
# $2: Output file to write to
# $3: The CPU cores to run the job on
function run {
	cpu_cores="$3"
	for (( core=1; core<$CORES_PER_PROCESS; core++ ))
	do
		cpu_cores="$cpu_cores,$(( $core * $MAX_PARALLEL_PROCESSES + $3 ))"
	done
	verifier=$(determine_verifier "$1")
	# Runs single-threaded and single-process programs with ulimit (sufficient)
	# Else, uses more complicated "timeout" to measure memory and time across
	# processes and threads. See: https://github.com/pshved/timeout
	if [[ "$verifier" = $TWOLS || "$verifier" = $CBMC ]]
	then
		(
		ulimit -v $(( MEMORY_PER_CALL * 1000000 )) -t $(( TIME_PER_CALL * 60 ))
		taskset -c "$cpu_cores" /usr/bin/time -v $1 >> $2 2>&1
		)
	else
		timeout --memlimit-rss $(( MEMORY_PER_CALL * 1000000 )) -t $(( TIME_PER_CALL * 60 )) taskset -c "$cpu_cores" /usr/bin/time -v $1 >> $2 2>&1
	fi
	# Performs witness validation.
	witness_location=$(determine_witness_location "$(< $2)")
	result=$(determine_verifier_result "$(< $2)")
	witness_validation_call_cpa=$(assemble_validation_call_cpachecker "$witness_location" "$1")
	witness_validation_call_ult=$(assemble_validation_call_ultimate "$witness_location" "$1")
	if [[ "$result" = "True" ]]
	then
		echo "Results of proof witness validation 1, located in $witness_location.
Validation 1 executed: $witness_validation_call_cpa" >> $2
		timeout --memlimit-rss $(( MEMORY_PER_PROOF_VALIDATION * 1000000 )) -t $(( TIME_PER_PROOF_VALIDATION * 60 )) taskset -c "$cpu_cores" /usr/bin/time -v $witness_validation_call_cpa >> $2 2>&1
		echo "Results of proof witness validation 2, located in $witness_location.
Validation 2 executed: $witness_validation_call_ult" >> $2
		timeout --memlimit-rss $(( MEMORY_PER_PROOF_VALIDATION * 1000000 )) -t $(( TIME_PER_PROOF_VALIDATION * 60 )) taskset -c "$cpu_cores" /usr/bin/time -v $witness_validation_call_ult >> $2 2>&1
	elif [[ "$result" = "False" ]]
	then
		echo "Results of counterexample witness validation 1, located in $witness_location.
Validation 1 executed: $witness_validation_call_cpa" >> $2
		timeout --memlimit-rss $(( MEMORY_PER_COUNTEREXAMPLE_VALIDATION * 1000000 )) -t $(( TIME_PER_COUNTEREXAMPLE_VALIDATION * 60 )) taskset -c "$cpu_cores" /usr/bin/time -v $witness_validation_call_cpa >> $2 2>&1
		echo "Results of counterexample witness validation 2, located in $witness_location.
Validation 2 executed: $witness_validation_call_ult" >> $2
		timeout --memlimit-rss $(( MEMORY_PER_COUNTEREXAMPLE_VALIDATION * 1000000 )) -t $(( TIME_PER_COUNTEREXAMPLE_VALIDATION * 60 )) taskset -c "$cpu_cores" /usr/bin/time -v $witness_validation_call_ult >> $2 2>&1
	fi
}

# Prepares the call string for a given call and a file, i.e. inserts the file
# to the right location of the call.
# $1: Program call string
# $2: File
# $3: Verifier name
function prepare_call_string {
	witness_location=$(determine_witness_location "$1 $2")
	witness_filename=${witness_location//$WITNESS_FOLDER\//}
	case $3 in
		$CPACHECKER)
			echo "$1 -setprop cpa.arg.proofWitness=$witness_location -setprop counterexample.export.graphml=$witness_location $2"
		;;
		$PESCO)
			echo "$1 -setprop cpa.arg.proofWitness=$witness_location -setprop counterexample.export.graphml=$witness_location $2"
		;;
		$ULTIMATE)
			echo "$1 --witness-dir $WITNESS_FOLDER --witness-name $witness_filename --file $2"
		;;
		$ULTIMATEKOJAK)
			echo "$1 --witness-dir $WITNESS_FOLDER --witness-name $witness_filename --file $2"
		;;
		$ULTIMATETAIPAN)
			echo "$1 --witness-dir $WITNESS_FOLDER --witness-name $witness_filename --file $2"
		;;
		$SMACK)
			echo "$1 -w $witness_location $2"
		;;
		$CBMC)
			echo "$1 -graphml-witness $witness_location $2"
		;;
		$ESBMC)
			echo "$1 --witness-output $witness_location $2"
		;;
		$TWOLS)
			echo "$1 --graphml-witness $witness_location $2"
		;;
		$SYMBIOTIC)
			echo "$1 --witness=$witness_location $2"
		;;
		$DEPTHK)
			echo "$1 $witness_location $2"
		;;
		$KINDUCTION)
			echo "$1 $2"
		;;
		*)
			echo "ERROR: Verifier $3 is not known!" >> /dev/stderr
		;;
	esac
}

# Creates the output file for the given program command. Returns its path.
# Writes the following contents to its returned output file:
# The programm call string
# The Ford requirement ID
# $1: Program call string
# Returns the output file to which the output is written to
function determine_output_file {
	tmp_output_file=$(mktemp --tmpdir=$VERIFIER_OUTPUT_FOLDER)
	echo "$tmp_output_file"
	echo "$@" >> $tmp_output_file
	echo $(determine_requirement $1) >> $tmp_output_file
}

# Finds the witness location when given a verifier output.
# $1: Verifier output as string, or call string.
function determine_witness_location {
	call_string=$(echo "$1" | head -n 1)
	input_c_file=$(basename $(echo "$call_string" | rev | cut -d" " -f1 | rev))
	verifier=$(determine_verifier_config_combination "$call_string")
	echo "$WITNESS_FOLDER/${input_c_file%.c}_${verifier}.graphml"
}

# Creates the CPAChecker witness validation call string from the witness 
# location.	
# $1: The location of the verification witness that has to be validated
# $2: The original call string of the verification run
function assemble_validation_call_cpachecker {
	input_c_file=$(echo "$2" | rev | cut -d" " -f1 | rev)
	call_string="cpa-git.sh -heap ${MEMORY_PER_PROOF_VALIDATION}G -witnessValidation -witness $1 -spec /home/lw338104/tools/cpachecker/scripts/reach.prp $input_c_file"
	echo "$call_string"
}

# Creates the Ultimate witness validation call string from the witness
# location.
# $1: The location of the verification witness that has to be validated
# $2: The original call string of the verification run
function assemble_validation_call_ultimate {
	input_c_file=$(echo "$2" | rev | cut -d" " -f1 | rev)
	call_string="Ultimate.py --validate $1 --spec /home/lw338104/tools/ultimate/config/svcomp-Reach-32bit-Automizer_Bitvector.epf --architecture 32bit --file $input_c_file"
	echo "$call_string"
}

# Checks if a key is in a given array (https://stackoverflow.com/a/13221491).
# $1: Key
# $2: Array
function exists {
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: exists {key} in {array}"
    return
  fi
  eval '[ ${'$3'[$1]+abc} ]'
}

###############################################################################
# Benchmark output interpretation and collection functions                    #
###############################################################################

# Identifies the verifier's answer given a verifier output. An answer can
# either be "True", "False" or "Unknown".
# $1: Verifier output as string
function determine_verifier_result {
	answer="Unknown"
	verifier=$(determine_verifier "$(echo "$1" | head -n 1)")
	case $verifier in
		$CPACHECKER)
			if [[ "$1" = *"Verification result: FALSE"* ]]; then
				answer="False"
			elif [[ "$1" = *"Verification result: TRUE"* ]]; then
				answer="True"
			fi
		;;
		$PESCO)
			if [[ "$1" = *"Verification result: FALSE"* ]]; then
				answer="False"
			elif [[ "$1" = *"Verification result: TRUE"* ]]; then
				answer="True"
			fi
		;;
		$ULTIMATE)
			if [[ "$1" = *"Result:"*"FALSE"* || "$1" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				answer="False"
			elif [[ "$1" = *"Result:"*"TRUE"* || "$1" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				answer="True"
			fi
		;;
		$ULTIMATEKOJAK)
			if [[ "$1" = *"Result:"*"FALSE"* || "$1" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				answer="False"
			elif [[ "$1" = *"Result:"*"TRUE"* || "$1" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				answer="True"
			fi
		;;
		$ULTIMATETAIPAN)
			if [[ "$1" = *"Result:"*"FALSE"* || "$1" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				answer="False"
			elif [[ "$1" = *"Result:"*"TRUE"* || "$1" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				answer="True"
			fi
		;;
		$SMACK)
			if [[ "$1" = *"SMACK found an error"* ]]; then
				answer="False"
			fi
		;;
		$CBMC)
			if [[ "$1" = *"VERIFICATION FAILED"* ]]; then
				answer="False"
			fi
		;;
		$ESBMC)
			if [[ "$1" = *"VERIFICATION FAILED"* ]]; then
				answer="False"
			elif [[ "$1" = *"VERIFICATION SUCCESSFUL"* ]]; then
				answer="True"
			fi
		;;
		$TWOLS)
			if [[ "$1" = *"VERIFICATION FAILED"* ]]; then
				answer="False"
			elif [[ "$1" = *"VERIFICATION SUCCESSFUL"* ]]; then
				answer="True"
			fi
		;;
		$SYMBIOTIC)
			if [[ "$1" = *"RESULT: false"* ]]; then
				answer="False"
			elif [[ "$1" = *"RESULT: true"* ]]; then
				answer="True"
			fi
		;;
		$DEPTHK)
			if [[ "$1" = *"FALSE"* ]]; then
				answer="False"
			elif [[ "$1" = *"TRUE"* ]]; then
				answer="True"
			fi
		;;
		$KINDUCTION)
			if [[ "$1" = *"VERIFICATION FAILED"* ]]; then
				answer="False"
			elif [[ "$1" = *"VERIFICATION SUCCESSFUL"* ]]; then
				answer="True"
			fi
		;;
	esac
	echo "$answer"
}

# Determines the result of CPAChecker's validation run from the output.
# $1: Verifier and validation run output as string
function determine_validation_result_cpachecker {
	verifier_output=$(echo "$1" | sed -n '/Validation 1 executed/q;p')
	verifier_result=$(determine_verifier_result "$verifier_output")
	if [[ "$verifier_result" != "Unknown" ]]
	then
		validation_output=$(echo "$1" | awk '/Validation 1 executed:/{f=1;} /Validation 2 executed:/{f=0} f')
		validation_result=$(determine_verifier_result "$validation_output")
		if [[ "$verifier_result" = "$validation_result" ]]
		then
			echo "Correct"
		elif [[ "$validation_output" = *"Invalid configuration:"* ]] && [[ ! "$validation_output" = *"Error while accessing witness file"* ]]
		then
			echo "Invalid"
		else
			echo "Unknown"
		fi
	else
		echo "Unknown"
	fi
}

# Determines the result of Ultimate's validation run from the output.
# $1: Verifier and validation run output as string
function determine_validation_result_ultimate {
	verifier_output=$(echo "$1" | sed -n '/Validation 1 executed/q;p')
	verifier_result=$(determine_verifier_result "$verifier_output")
	if [[ "$verifier_result" != "Unknown" ]]
	then
		validation_output=$(echo "$1" | sed -n '/Validation 2 executed:/,$p')
		validation_result=$(determine_verifier_result "$validation_output")
		if [[ "$verifier_result" = "$validation_result" ]]
		then
			echo "Correct"
		elif [[ "$validation_output" = *"ERROR: INVALID WITNESS FILE"* ]]
		then
			echo "Invalid"
		else
			echo "Unknown"
		fi
	else
		echo "Unknown"
	fi
}

# Appends the given output to the csv file.
# $1: File to write to
# $2: File location string containing program, validation and time output
function output_to_csv {
	# Variables for all the outputs we store per data row.
	call=$(cat "$2" | sed '1q;d')
	output=$(cat "$2")
	requirement=$(determine_requirement "$call")
	result="Unidentifiable"
	reason=""
	time=""
	peak_memory=""
	depth=""
	validation_result_cpachecker=$(determine_validation_result_cpachecker "$output")
	validation_result_ultimate=$(determine_validation_result_ultimate "$output")
	verifier_output=$(echo "$output" | sed -n '/Validation 1 executed/q;p')
	verifier=$(determine_verifier "$(echo "$verifier_output" | head -n 1)")
	witness_location=$(determine_witness_location "$verifier_output")
	# Fetching result and reason. Outsourced for readability.
	verifier_output_interpretation
	depth=$(determine_k "$verifier" "$verifier_output")
	# Collecting statistics. First trying timeout output, then /usr/bin/time.
	time=$(echo "$verifier_output" | grep -o -P '(?<=CPU ).*(?= MEM)') # s
	if [[ -z "$time" || "$time" = "0" || "$time" = "0.00" ]]
	then
		user_time=$(echo "$verifier_output" | sed -n 's/\tUser time (seconds): //p')
		system_time=$(echo "$verifier_output" | sed -n 's/\tSystem time (seconds): //p')
		time=$(echo $user_time $system_time | awk '{print $1 + $verifier_output}') # s
	fi
	if [[ -z "$time" ]]
	then
		time="0"
	fi
	statsline=$(echo "$verifier_output" | grep "MAXMEM")
	pm=${statsline#*MAXMEM_RSS }
	if [[ -z "$pm" || "$pm" -eq "0" ]]
	then
		pm=$(echo "$verifier_output" | sed -n 's/\tMaximum resident set size (kbytes): //p')
	fi
	if [[ -z "$pm" ]]
	then
		pm="0"
	fi
	peak_memory=$(( pm / 1000 )) # MB
	smt_time=$(determine_smt_time "$verifier" "$verifier_output")
	# Prints single data row for this verification run.
	out="$call;$requirement;$result;$reason;$time;$peak_memory;$smt_time;$depth;$validation_result_cpachecker;$validation_result_ultimate;$2;$witness_location"
	echo -e "$out" >> "$1"
}

# Creates an empty CSV file with the correct header for the given verifier.
# $1: File
# $2: Verifier name
function create_csv {
	out="Command;Requirement;Result;Reason;CPU-Time [s];Peak memory [MB];SMT CPU-Time [s];Depth;Validation result CPAChecker;Validation result Ultimate;Output file;Witness file"
	echo "$out" > "$1"
}

# Determines an appropriate, unused filename for the given program call.
# $1: Program call string
# $2: The folder to write to
function determine_csv_filename {
	filename="${1//\//_}"
	filename="${filename// /_}_${MEMORY_PER_CALL}GB_${TIME_PER_CALL}m"
	new_filename="${filename}.csv"
	i=0
	while [ -f "$2/$new_filename" ]
	do
		new_filename="${filename%.*}_$i.csv"
		i=$(( i + 1 ))
	done
	# Truncat in case filename is over 255 byte limit.
	if [ $(echo $new_filename | wc -c) -gt 256 ]
	then
		new_filename=${new_filename: -255}
	fi
	echo "$2/$new_filename"
}

# Determines the verifier given a call string. Returns on of the constant
# verifier names.
# $1: Program call string
function determine_verifier {
	if [[ "$1" = *"cpa.sh"* ]]
	then
		echo $CPACHECKER
	elif [[ "$1" = *"cpa-git.sh"* ]]
	then
		echo $CPACHECKER
	elif [[ "$1" = *"pesco.sh"* ]]
	then
		echo $PESCO
	elif [[ "$1" = *"Ultimate.py"* ]]
	then
		echo $ULTIMATE;
	elif [[ "$1" = *"UltimateKojak.py"* ]]
	then
		echo $ULTIMATEKOJAK;
	elif [[ "$1" = *"UltimateTaipan.py"* ]]
	then
		echo $ULTIMATETAIPAN;
	elif [[ "$1" = *"smack"* ]]
	then
		echo $SMACK;
	elif [[ "$1" = *"depthk"* ]]
	then
		echo $DEPTHK;
	elif [[ "$1" = *"esbmc"* ]]
	then
		echo $ESBMC;
	elif [[ "$1" = *"2ls"* ]]
	then
		echo $TWOLS;
	elif [[ "$1" = *"symbiotic"* ]]
	then
		echo $SYMBIOTIC;
	elif [[ "$1" = *"kinduction.py"*  ]]
	then
		echo $KINDUCTION;
	elif [[ "$1" = *"cbmc"*  ]]
	then
		echo $CBMC;
	else
		echo "ERROR: Verifier could not be detected from call string $1" >> /dev/stderr
	fi
}

# Similar to determine_verifier, but returns a name unique to the combination
# of the employed verifier-configuration, e.g. CPAChecker_ValueAnalysis instead
# of just CPAChecker.
# $1: Program call string
function determine_verifier_config_combination {
	if [[ "$1" = *"cpa.sh"* ]]
	then
		if [[ "$1" = *"-valueAnalysis"* ]]
		then
			echo "${CPACHECKER}_ValueAnalysis"
		elif [[ "$1" = *"-predicateAnalysis"* ]]
		then
			echo "${CPACHECKER}_PredicateAnalysis"
		elif [[ "$1" = *"-bmc-induction"* ]]
		then
			echo "${CPACHECKER}_kInduction"
		else
			echo "$CPACHECKER"
		fi
	elif [[ "$1" = *"pesco.sh"* ]]
	then
		echo "$PESCO"
	elif [[ "$1" = *"Ultimate.py"* ]]
	then
		if [[ "$1" = *"_z3.epf"* ]]
		then
			echo "${ULTIMATE}_Z3"
		elif [[ "$1" = *"_mathsat.epf"* ]]
		then
			echo "${ULTIMATE}_MathSAT"
		else
			echo "$ULTIMATE"
		fi
	elif [[ "$1" = *"UltimateKojak.py"* ]]
	then
		if [[ "$1" = *"_z3.epf"* ]]
		then
			echo "${ULTIMATEKOJAK}_Z3"
		elif [[ "$1" = *"_mathsat.epf"* ]]
		then
			echo "${ULTIMATEKOJAK}_MathSAT"
		else
			echo "$ULTIMATEKOJAK"
		fi
	elif [[ "$1" = *"UltimateTaipan.py"* ]]
	then
		if [[ "$1" = *"_z3.epf"* ]]
		then
			echo "${ULTIMATETAIPAN}_Z3"
		elif [[ "$1" = *"_mathsat.epf"* ]]
		then
			echo "${ULTIMATETAIPAN}_MathSAT"
		else
			echo "$ULTIMATETAIPAN"
		fi
	elif [[ "$1" = *"smack"* ]]
	then
		echo "$SMACK"
	elif [[ "$1" = *"esbmc"* ]]
	then
		if [[ "$1" = *"-boolector"* ]]
		then
			echo "${ESBMC}_Boolector"
		else
			echo "$ESBMC"
		fi
	elif [[ "$1" = *"2ls"* ]]
	then
		if [[ "$1" = *"--havoc"* ]]
		then
			echo "${TWOLS}_kInduction"
		elif [[ "$1" = *"--k-induction"* ]]
		then
			echo "${TWOLS}_kInduction_kInvariant"
		else
			echo "$TWOLS"
		fi
	elif [[ "$1" = *"symbiotic"* ]]
	then
		echo "$SYMBIOTIC"
	elif [[ "$1" = *"depthk"* ]]
	then
		echo "$DEPTHK"
	elif [[ "$1" = *"kinduction.py"*  ]]
	then
		echo "$KINDUCTION"
	elif [[ "$1" = *"cbmc"*  ]]
	then
		if [[ "$1" = *"cbmc--incremental.sh"* ]]
		then
			echo "${CBMC}_Incremental"
		elif [[ "$1" = *"cbmc-incremental.sh"* ]]
		then
			echo "${CBMC}_Incremental_Wrapper"
		else
			echo "$CBMC"
		fi
	else
		echo "ERROR: Verifier could not be detected from call string $1!" >> /dev/stderr
	fi
}

# Extracts the Ford requirement ID from the program call string.
# $1: Program call string.
function determine_requirement {
	echo "$1" | rev | cut -d ' ' -f 1 | rev | grep -o -P '(?<=(dsr-|ecc-)).*(?=.c)'
}

# Determines the number of iterations on either BMC or k-Induction.
# Works only for CBMC, CBMC+k, and ESBMC.
# $1: Verifier
# $2: Program output
function determine_k {
	k="0"
	case $1 in
		$CBMC)
			k=$(echo "$2" | grep "Not unwinding" | tail -1 | grep -o -P '(?<= unroll bound ).*(?=.)')
			if [ -z "$k" ]
			then
				k=$(echo "$2" | grep "Not unwinding" | tail -1 | grep -o -P '(?<=Not unwinding loop main.0 iteration ).*(?= \()')
			fi
			if [[ ! $k =~ ^-?[0-9]+$ ]]
			then
				k=$(echo "$2" | grep "Not unwinding" | tail -1 | grep -o -P '(?<=Not unwinding loop main.0 iteration ).*(?= file)')
			fi
			if [ -z "$k" ]
			then
				k=$(echo "$2" | grep "No counterexample found up to depth" | tail -1 | grep -o -P '(?<=No counterexample found up to depth ).*(?=. Remaining time)')
			fi
		;;
		$KINDUCTION)
			if [[ "$2" = *"VERIFICATION FAILED"* ]]; then
				k=$(echo "$2" | grep -oP "(?<=Base step k = ).*" | tail -1)
			elif [[ "$2" = *"VERIFICATION SUCCESSFUL"* ]]; then
				k=$(echo "$2" | grep -oP "(?<=Induction step k = ).*" | tail -1)
			else
				k=$(echo "$2" | grep -oP "(?<=Induction step k = ).*" | tail -1)
			fi
		;;
		$ESBMC)
			if [[ "$2" = *"VERIFICATION FAILED"* ]]; then
				k=$(echo "$2" | grep -oP "(?<=---------- BASE CASE ).*(?= ----------)" | tail -1)
			elif [[ "$2" = *"VERIFICATION SUCCESSFUL"* ]]; then
				k=$(echo "$2" | grep -oP "(?<=---------- INDUCTION STEP ).*(?= ----------)" | tail -1)
			else
				k=$(echo "$2" | grep -oP "(?<=---------- INDUCTION STEP ).*(?= ----------)" | tail -1)
			fi
			if [ -z "$k" ]; then
				k=$(echo "$2" | grep "Not unwinding" | tail -1 | grep -o -P '(?<=iteration ).*(?=\ file)')
			fi
		;;
	esac
	echo "$k"
}

# Determines the time spent on SMT/SAT solving given the verifier and output.
# $1: Verifier
# $2: Program output
function determine_smt_time {
	smt_time="0"
	case $1 in
		$CPACHECKER)
			prd_smt_time=$(echo "$2" | grep "Total time for SMT solver" | tr -s ' ' | grep -o -P '(?<=Total time for SMT solver \(w/o itp\): ).*(?=s)' | rev | cut -c 2- | rev)
			bmc_smt_time=$(echo "$2" | grep "Time for final sat check" | tr -s ' ' | grep -o -P '(?<=Time for final sat check: ).*(?=s)' | rev | cut -c 2- | rev)
			smt_time=$(echo "$prd_smt_time $bmc_smt_time" | awk '{print $1 + $2}')
		;;
		$PESCO)
			prd_smt_time=$(echo "$2" | grep "Total time for SMT solver" | tr -s ' ' | grep -o -P '(?<=Total time for SMT solver \(w/o itp\): ).*(?=s)' | rev | cut -c 2- | rev)
			bmc_smt_time=$(echo "$2" | grep "Time for final sat check" | tr -s ' ' | grep -o -P '(?<=Time for final sat check: ).*(?=s)' | rev | cut -c 2- | rev)
			smt_time=$(echo "$prd_smt_time $bmc_smt_time" | awk '{print $1 + $2}')
		;;
		$CBMC|$ESBMC)
			smt_time=$(echo "$2" | grep "Runtime decision procedure" | grep -o -P '(?<=Runtime decision procedure: ).*(?=s)' | rev | cut -c 4- | rev | awk 'BEGIN {SUM=0}; {SUM=SUM+$0}; END {printf "%.2f\n", SUM}')
		;;
		$KINDUCTION)
			smt_time=$(echo "$2" | grep "Runtime SMT-solver: " | grep -o -P '(?<=Runtime SMT-solver: ).*(?=s)' | awk 'BEGIN {SUM=0}; {SUM=SUM+$0}; END {printf "%.2f\n", SUM}')
		;;
		*)
			echo "ERROR: SMT-Time: Verifier $1 could not be detected!" >> /dev/stderr
		;;
	esac
	echo "$smt_time"
}

###############################################################################
# Main benchmarking and interface functions                                   #
###############################################################################

# Determines and returns the next free CPU core number that we can use.
function determine_cpu_core {
	for core in `seq 0 $(( MAX_PARALLEL_PROCESSES - 1 ))`
	do
		if ! exists "$core" in CPU_CORE_TO_JOBID || [ "${CPU_CORE_TO_JOBID[$core]}" -eq 0 ]
		then
			echo "$core"
			exit
		fi
	done
}

# Determines whether a job at the given core is running or not.
# $1: The core number on which the job was started.
function is_job_running {
	run_jobs=$(jobs -r | grep "Running" | cut -d "[" -f2 | cut -d "]" -f1)
	echo "$run_jobs" | while read job
	do
		if [[ ${CPU_CORE_TO_JOBID[$1]} -eq $job ]]
		then
			echo "$job is running"
		fi
	done
}

# Creates a progress bar. See: https://github.com/fearside/ProgressBar
# $1: Current state of progress
# $2: Max. state of progress
function progressbar {
	# Process data
	 let _progress=(${1}*100/${2}*100)/100
	 let _done=(${_progress}*4)/10
	 let _left=40-$_done
	 let _finished=${1}-${MAX_PARALLEL_PROCESSES}
	 if [ $_finished -lt 0 ]; then _finished=0; fi
	 let _hours=(${2}-${_finished})*${TIME_PER_CALL}*3/60/${MAX_PARALLEL_PROCESSES}
	# Build progressbar string lengths
	 _fill=$(printf "%${_done}s")
	 _empty=$(printf "%${_left}s")
	# 1.2 Build progressbar strings and print the ProgressBar line
	# 1.2.1 Output example:
	# 1.2.1.1 Progress : [########################################] 100%
	printf "\rJobs started: [${_fill// /#}${_empty// /-}] ${_progress}%% ${_hours}h"
}

# Executes the given program call for each file in the given folder.
# $1: Program call string
# $2: Input file folder
# $3: Output file folder
function run_batch {
	declare -A call_strings_to_output_files
	total_call_number=0
	verifier=$(determine_verifier "$1")
	csv=$(determine_csv_filename "$1" "$3")
	create_csv "$csv" "$verifier"

	echo "Executing the following commands as batch jobs:"
	# Preparing commands and output files.
	for file in $2/*.c
	do
		if [[ "$file" != *"new_depthk"* ]] # Thanks, DepthK!
		then
			call_string=$(prepare_call_string "$1" "$file" "$verifier")
			output_file=$(determine_output_file "$call_string")
			call_strings_to_output_files[$call_string]="$output_file"
			echo "$call_string > $output_file"
			total_call_number=$(( total_call_number + 1 ))
		fi
	done

	# Actually running the tasks, with a progress bar.
	echo "Starting batch benchmark."
	current_call_number=0
	for call_string in "${!call_strings_to_output_files[@]}"
	do
		cpu_core=$(determine_cpu_core)
		# Starts the verification run in a background shell.
		(
		run "$call_string" "${call_strings_to_output_files[$call_string]}" "$cpu_core"
		)&
		# Registers the CPU core as used by the job.
		new_job=$(jobs -lr | grep "$!" | cut -d "[" -f2 | cut -d "]" -f1)
		CPU_CORE_TO_JOBID[$cpu_core]=$new_job
		current_call_number=$(( current_call_number + 1 ))
		progressbar $current_call_number $total_call_number
		# Waits until a process finishes so we can start a new one.
		while [[ $(jobs -r | wc -l) = $MAX_PARALLEL_PROCESSES ]]; do sleep 1; done
		# Removes all non-running processes from the used CPU core list.
		for (( i=0; i<$MAX_PARALLEL_PROCESSES; i+=1 ))
		do
			if [[ ! $(is_job_running $i) ]]; then CPU_CORE_TO_JOBID[$i]=0; fi
		done
	done

	echo
	wait

	# Writing the tasks' outputs.
	for call_string in "${!call_strings_to_output_files[@]}"
	do
		output_to_csv "$csv" "${call_strings_to_output_files[$call_string]}"
	done
	echo "Results are in $csv"
}