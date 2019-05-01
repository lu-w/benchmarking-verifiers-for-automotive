function verifier_output_interpretation {
	# Note: The output interpretation is pretty indigestible, and should be cleared up.
	case $verifier in
		$CPACHECKER)
			if [[ "$verifier_output" = *"Verification result: FALSE"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"Verification result: TRUE"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"Verification result: UNKNOWN"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"There is insufficient memory for the Java Runtime Environment to continue."* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"java.lang.OutOfMemoryError"* || "$verifier_output" = *"std::bad_alloc"* || "$verifier_output" = *"Segmentation fault"* || "$verifier_output" = *"MEM CPU"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"(The CPU-time limit of"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Command terminated by signal 9"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Analysis incomplete:"* ]]; then
					reason="Incomplete analysis"
				elif [[ "$verifier_output" = *"Error: Parsing failed"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"Interpolation failed"* ]]; then
					reason="Unsupported verification technique"
				elif [[ "$verifier_output" = *"Counterexample could not be ruled out"* ]]; then
					reason="Unverifyable counterexample"
				elif [[ "$verifier_output" = *"Exception in thread"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"Invalid configuration"* ]]; then
					reason="Misconfiguration"
				else
					rsn="${verifier_output//;}"
					reason="$CPACHECKER: Non identifiable output"
				fi
			fi
		;;
		$PESCO)
			if [[ "$verifier_output" = *"Verification result: FALSE"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"Verification result: TRUE"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"Verification result: UNKNOWN"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"There is insufficient memory for the Java Runtime Environment to continue."* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"java.lang.OutOfMemoryError"* || "$verifier_output" = *"std::bad_alloc"* || "$verifier_output" = *"Segmentation fault"* || "$verifier_output" = *"MEM CPU"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"(The CPU-time limit of"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Command terminated by signal 9"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Analysis incomplete:"* ]]; then
					reason="Incomplete analysis"
				elif [[ "$verifier_output" = *"Error: Parsing failed"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"Interpolation failed"* ]]; then
					reason="Unsupported verification technique"
				elif [[ "$verifier_output" = *"Counterexample could not be ruled out"* ]]; then
					reason="Unverifyable counterexample"
				elif [[ "$verifier_output" = *"Exception in thread"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"Invalid configuration"* ]]; then
					reason="Misconfiguration"
				else
					rsn="${verifier_output//;}"
					reason="$PESCO: Non identifiable output"
				fi
			fi
		;;
		$ULTIMATE)
			if [[ "$verifier_output" = *"Result:"*"FALSE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"Result:"*"TRUE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"Result:"*"UNKNOWN"* || "$verifier_output" = *"RESULT: Ultimate could not prove your program"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"There is insufficient memory for the Java Runtime Environment to continue."* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"java.lang.OutOfMemoryError"* || "$verifier_output" = *"std::bad_alloc"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* || "$verifier_output" = *"out of memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Timeout"* || "$verifier_output" = *"Command terminated by signal 9"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Unsupported Syntax"* || "$verifier_output" = *"Incorrect Syntax"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"TypeErrorResult"* || "$verifier_output" = *"ExceptionOrErrorResult"* || "$verifier_output" = *"ERROR: TYPE ERROR"* || "$verifier_output" = *"SMTLIBException"* || "$verifier_output" = *"An exception occured during the execution of Ultimate"* || "$verifier_output" = *"IllegalArgumentException"* || "$verifier_output" = *"An error has occurred."* ]]; then
					reason="Verifier bug"
				else
					rsn="${verifier_output//;}"
					reason="$ULTIMATE: Non identifiable output"
				fi
			fi
		;;
		$ULTIMATEKOJAK)
			if [[ "$verifier_output" = *"Result:"*"FALSE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"Result:"*"TRUE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"Result:"*"UNKNOWN"* || "$verifier_output" = *"RESULT: Ultimate could not prove your program"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"There is insufficient memory for the Java Runtime Environment to continue."* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"java.lang.OutOfMemoryError"* || "$verifier_output" = *"std::bad_alloc"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* || "$verifier_output" = *"out of memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Timeout"* || "$verifier_output" = *"Command terminated by signal 9"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Unsupported Syntax"* || "$verifier_output" = *"Incorrect Syntax"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"TypeErrorResult"* || "$verifier_output" = *"ExceptionOrErrorResult"* || "$verifier_output" = *"ERROR: TYPE ERROR"* || "$verifier_output" = *"SMTLIBException"* || "$verifier_output" = *"An exception occured during the execution of Ultimate"* || "$verifier_output" = *"IllegalArgumentException"* || "$verifier_output" = *"An error has occurred."* ]]; then
					reason="Verifier bug"
				else
					rsn="${verifier_output//;}"
					reason="$ULTIMATEKOJAK: Non identifiable output"
				fi
			fi
		;;
		$ULTIMATETAIPAN)
			if [[ "$verifier_output" = *"Result:"*"FALSE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be incorrect"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"Result:"*"TRUE"* || "$verifier_output" = *"RESULT: Ultimate proved your program to be correct"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"Result:"*"UNKNOWN"* || "$verifier_output" = *"RESULT: Ultimate could not prove your program"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"There is insufficient memory for the Java Runtime Environment to continue."* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"java.lang.OutOfMemoryError"* || "$verifier_output" = *"std::bad_alloc"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* || "$verifier_output" = *"out of memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Timeout"* || "$verifier_output" = *"Command terminated by signal 9"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Unsupported Syntax"* || "$verifier_output" = *"Incorrect Syntax"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"TypeErrorResult"* || "$verifier_output" = *"ExceptionOrErrorResult"* || "$verifier_output" = *"ERROR: TYPE ERROR"* || "$verifier_output" = *"SMTLIBException"* || "$verifier_output" = *"An exception occured during the execution of Ultimate"* || "$verifier_output" = *"IllegalArgumentException"* || "$verifier_output" = *"An error has occurred."* ]]; then
					reason="Verifier bug"
				else
					rsn="${verifier_output//;}"
					reason="$ULTIMATETAIPAN: Non identifiable output"
				fi
			fi
		;;
		$SMACK)
			if [[ "$verifier_output" = *"SMACK found an error"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"SMACK found no errors with unroll bound"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Command terminated by signal 6"* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"SMACK timed out"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"core dumped"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"no errors"* ]]; then
					reason="Max. depth ($depth) reached"
				elif [[ "$verifier_output" = *" errors generated."* ]]; then
					reason="Parsing error"
				else
					rsn="${verifier_output//;}"
					reason="$SMACK: Non identifiable output"
				fi
			fi
		;;
		$CBMC)
			if [[ "$verifier_output" = *"VERIFICATION FAILED"* ]]; then
				result="False"
				reason=$(determine_k "$verifier" "$verifier_output")
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"core dumped"* || "$verifier_output" = *"Unexpected case: typecast"* || "$verifier_output" = *"SMT2 solver returned error message"* || "$verifier_output" = *"Assertion \`endptr!=str' failed."* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Command terminated by signal 6"* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"*  || "$verifier_output" = *"Out of memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"Timeouter after"* || "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* || "$verifier_output" = *"Killed"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"Not unwinding"* ]]; then
					reason="Max. depth reached"
				elif [[ "$verifier_output" = *"VERIFICATION SUCCESSFUL"* ]]; then
					reason="Max. depth reached"
				elif [[ "$verifier_output" = *"PARSING ERROR"* || "$verifier_output" = *"CONVERSION ERROR"* ]]; then
					reason="Parsing error"
				else
					rsn="${verifier_output//;}"
					reason="$CBMC: Non identifiable output"
				fi
			fi
		;;
		$ESBMC)
			if [[ "$verifier_output" = *"VERIFICATION FAILED"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"VERIFICATION SUCCESSFUL"* ]]; then
				result="True"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Command terminated by signal 6"* || "$verifier_output" = *"Command exited with non-zero status 6"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* ||  "$verifier_output" = *"Timed out"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"core dumped"* || "$verifier_output" = *"[boolector] boolector_cond"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"Not unwinding"* ]]; then
					reason="Max. depth reached"
				elif [[ "$verifier_output" = *"PARSING ERROR"* || "$verifier_output" = *"CONVERSION ERROR"* ]]; then
					reason="Parsing error"
				else
					rsn="${verifier_output//;}"
					reason="$ESBMC: Non identifiable output"
				fi
			fi
		;;
		$TWOLS)
			if [[ "$verifier_output" = *"VERIFICATION FAILED"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"VERIFICATION SUCCESSFUL"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"VERIFICATION INCONCLUSIVE"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"core dumped"* || "$verifier_output" = *"byte_extract flatting with non-constant size:"* || "$verifier_output" = *"bool simplify_exprt"* || "$verifier_output" = *"map_entry.literal_map.size()==width"* || "$verifier_output" = *"Irreducible control flow not supported"* || "$verifier_output" = *"equality without matching types"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* ||  "$verifier_output" = *"Timed out"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"PARSING ERROR"* || "$verifier_output" = *"CONVERSION ERROR"* ]]; then
					reason="Parsing error"
				else
					rsn="${verifier_output//;}"
					reason="$TWOLS: Non identifiable output"
				fi
			fi
		;;
		$SYMBIOTIC)
			if [[ "$verifier_output" = *"RESULT: false"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"RESULT: true"* ]]; then
				result="True"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"core dumped"* || "$verifier_output" = *"ESILENTLYCONCRETIZED"* || "$verifier_output" = *"bool simplify_exprt"* || "$verifier_output" = *"Irreducible control flow not supported"* || "$verifier_output" = *"equality without matching types"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* ||  "$verifier_output" = *"Timed out"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"RESULT: cex not-confirmed"* ]]; then
					reason="Unconfirmed counterexample"
				else
					rsn="${verifier_output//;}"
					reason="$SYMBIOTIC: Non identifiable output"
				fi
			fi
		;;
		$DEPTHK)
			if [[ "$verifier_output" = *"FALSE"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"TRUE"* ]]; then
				result="True"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"core dumped"* || "$verifier_output" = *"boolector_eq: nodes must have equal sorts"* || "$verifier_output" = *"[boolector] boolector_cond"* || "$verifier_output" = *"bool simplify_exprt"* || "$verifier_output" = *"Irreducible control flow not supported"* || "$verifier_output" = *"equality without matching types"* ]]; then
					reason="Verifier bug"
				elif [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* ||  "$verifier_output" = *"Timed out"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* || "$verifier_output" = *"OutOfMemoryException"* || "$verifier_output" = *"Segmentation fault"*  || "$verifier_output" = *"Insufficient memory"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"FINISHED CPU"* ]]; then
					reason="Finished"
				else
					rsn="${verifier_output//;}"
					reason="$DEPTHK: Non identifiable output"
				fi
			fi
		;;
		$KINDUCTION)
			if [[ "$verifier_output" = *"VERIFICATION FAILED"* ]]; then
				result="False"
			elif [[ "$verifier_output" = *"VERIFICATION SUCCESSFUL"* ]]; then
				result="True"
			elif [[ "$verifier_output" = *"VERIFICATION INCONCLUSIVE"* ]]; then
				result="Unknown"
			else
				result="Unknown"
			fi
			if [ $result = "Unknown" ]; then
				if [[ "$verifier_output" = *"TIMEOUT CPU"* || "$verifier_output" = *"Command terminated by signal 9"* ||  "$verifier_output" = *"Timeout"* || "$verifier_output" = *"killed"* || "$verifier_output" = *"Getötet"* ]]; then
					reason="Timeout"
				elif [[ "$verifier_output" = *"MEM_RSS CPU"* || "$verifier_output" = *"MEM CPU"* ]]; then
					reason="Out of memory"
				elif [[ "$verifier_output" = *"ParseError"* ]]; then
					reason="Parsing error"
				elif [[ "$verifier_output" = *"Traceback"* ]]; then
					reason="Verifier bug"
				else
					rsn="${verifier_output//;}"
					reason="$KINDUCTION: Non identifiable output"
				fi
			fi
		;;
	esac
}