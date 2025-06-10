#'  Process command-line arguments where each argument is
#'  prefixed (by default with --) and has an assigned value and return 
#'  a list with all arguments. 

#'  @param args command-line arguments in the format 'name=value name value'.
#'  @param prefix prefix used to identify arguments (default is '--').
#'  @return list of parameters with the format list(name=value)
#'  
#'  @examples
#'  args_parse('--arg1=value1,value2 --arg2 value3')
#'  # Returns: $arg1 [1] 'value1,value2'
#'  #          $arg2 [1] 'value3'


args_parse <- function(args, prefix = "--") {
    # Split the input arguments by '=' into a character vector.
    args = unlist(strsplit(args, "="))

    # Identify positions in the vector where the argument names 
    # (starting with the prefix) are located.
    positions <- which(grepl(prefix, args))

    # Initialize an empty list to store the parsed arguments.
    output = list()

    # Loop through each position to extract and process arguments.
    for (iter in seq_along(positions)) {
        # Current position of the argument name.
        i = positions[iter]

        # Position of the next argument name to determine the range of values.
        j = positions[iter + 1] - 1

        # If there is no next argument, use the end of the vector.
        j = ifelse(is.na(j), length(args), j)

        # Extract the arguments and values for the current argument.
        args_iter = args[i:j]

        # Remove the prefix from the argument name.
        name = gsub(prefix, "", args_iter[1])

        # Combine all values into a single string, separated by commas.
        values = paste0(args_iter[-1], collapse = ",")

        # Create a list with name as the key and combined values as the value.
        res = list(. = values)
        names(res) = name

        # Append the result to the output list.
        output = c(output, res)
    }

    # Return the final list of parsed arguments.
    return(output)
}





