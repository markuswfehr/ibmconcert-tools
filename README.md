# ibmconcert-tools
Helper tools for IBM Concert

## watsonx tools ##

*checkwatsonxkey.sh*
validate a given API key from the commandline for it's existence. Alternatively, the key can also be sourced from the 
configuration file .watsonx.env or the environment variable WATSONX_API_KEY.

If the API key is found, it looks up for project IDs and provides you with the three necessary values for WATSONX_API_KEY,
WATSONX_PROJECT_ID as well as the WATSONX_API_URL.

When you use this for tool for the first time or you have a new API key, store these 3 environment variables in .watsonx.env

*configWatsonx.sh*
populate the watsonx specific variables to your IBM concert openshift instance and restart the py_utils pod. Variables are
expected to be found in .watsonx.env or any other file you refer at the command line using -f option
