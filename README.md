# ibmconcert-tools
Helper tools for IBM Concert

## watsonx tools ##

[checkwatsonxkey.sh](watsonx/checkwatsonxkey.sh)

Validate a given API key for it's existence and provide associated project IDs.

The API key is either given 
- at the command line as an argument
- sourced from the configuration file .watsonx.env
- set as an WATSONX_API_KEY.

If the API key is found, it looks up for project IDs and provides you with the three necessary values for WATSONX_API_KEY,
WATSONX_PROJECT_ID as well as the WATSONX_API_URL.

Hint: When you use this tool for the first time or you have a new API key, store these 3 environment variables in .watsonx.env

[configWatsonx.sh](watsonx/configWatsonx.sh)

Populate the watsonx specific variables to your IBM concert openshift instance and restart the py_utils pod. Variables are
expected to be found in .watsonx.env or any other file you refer at the command line using -f option
You must be logged in to your OpenShift cluster.
