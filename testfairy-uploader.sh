#!/bin/sh

# This upload script is both for iOS and Android
UPLOADER_VERSION=2.15

# TestFairy API_KEY. Find it here: https://app.testfairy.com/settings/access-key
# Required Parameter
TESTFAIRY_API_KEY=

# Symbols mapping file (optional)
# For iOS, this is a path to the zipped symbols file (dSYM). For Android, this is the path to the .txt file
SYMBOLS_FILE=

# Notify testers of updated build via email (optional)
# It can be "on" or "off". Default is "off"
NOTIFY=

# Comma-separated list of tester groups that get permission to download this app. (required if NOTIFY is on)
GROUPS=

# Allows to upgrade all users to the current version (optional)
AUTO_UPDATE=

# Set of comma-separated tags to be displayed and searched upon (optional)
TAGS=

# Name of the dashboard folder that contains this app (optional)
FOLDER_NAME=

# Release notes (optional)
# This text adds to emails and landing pages
RELEASE_NOTES=

# Landing page mode (optional)
# It can be "open" or "closed". Default is "open"
LANDING_PAGE_MODE=

# Upload file directly to Sauce Labs App Management (optional)
# It can be "on" or "off". Default is "off".
UPLOAD_TO_SAUCELABS=

# In case the app is not iOS or Android (optional)
# Values can be "Xbox", "PlayStation", "switch", "windows", "macos". 
# This feature is not enabled by default. Contact support for more information.
PLATFORM=

# locations of various tools
CURL=curl

# TestFairy API Endpoint
API_ENDPOINT=https://app.testfairy.com/api/upload/

# Display usage information
usage() {
    echo "Usage: sh $0 /path/to/your/APP_FILENAME"
    echo "Alternate Usage (if sh does not work): bash $0 /path/to/your/APP_FILENAME"
    echo "If no argument is provided, a default file path will be used."
}

# Verify that all required tools are installed.
verify_tools() {
    "${CURL}" --help >/dev/null || {
        echo "Error: Could not run curl. Please check your settings."
        exit 1
    }
}

verify_settings() {
    # Check if API Key is set. If not, exit with error message.
    if [ -z "${TESTFAIRY_API_KEY}" ]; then
        usage
        echo "Error: API Key is missing. Please update the script with your private API key."
        exit 1
    fi
}

# Main method
main() {
    # Use a default file path if no argument is provided in the command line.
    if [ $# -eq 0 ]; then
        APP_FILENAME="/path/to/your/APP_FILENAME"
    else
        APP_FILENAME="$1"
    fi

    verify_tools
    verify_settings

    # Verify the file exists. If file is missing, exit with error message.
    if [ ! -f "${APP_FILENAME}" ]; then
        usage
        echo "Error: File not found - ${APP_FILENAME}"
        exit 2
    fi

    # Build required curl arguments.
    CURL_ARGS="-F api_key=${TESTFAIRY_API_KEY} -F file=@${APP_FILENAME}"

    # Append optional parameters if provided.
    [ -n "$RELEASE_NOTES" ] && CURL_ARGS="${CURL_ARGS} -F release_notes=@${RELEASE_NOTES}"
    [ -n "$GROUPS" ] && CURL_ARGS="${CURL_ARGS} -F tester_groups=@${GROUPS}"
    [ -n "$AUTO_UPDATE" ] && CURL_ARGS="${CURL_ARGS} -F auto_update=@${AUTO_UPDATE}"
    [ -n "$NOTIFY" ] && CURL_ARGS="${CURL_ARGS} -F notify_testers=@${NOTIFY}"
    [ -n "$SYMBOLS_FILE" ] && CURL_ARGS="${CURL_ARGS} -F symbols_mapping_file=@${SYMBOLS_FILE}"
    [ -n "$TAGS" ] && CURL_ARGS="${CURL_ARGS} -F tags=${TAGS}"
    [ -n "$FOLDER_NAME" ] && CURL_ARGS="${CURL_ARGS} -F folder_name=${FOLDER_NAME}"
    [ -n "$LANDING_PAGE_MODE" ] && CURL_ARGS="${CURL_ARGS} -F landing_page_mode=${LANDING_PAGE_MODE}"
    [ -n "$UPLOAD_TO_SAUCELABS" ] && CURL_ARGS="${CURL_ARGS} -F upload_to_saucelabs=${UPLOAD_TO_SAUCELABS}"
    [ -n "$PLATFORM" ] && CURL_ARGS="${CURL_ARGS} -F platform=${PLATFORM}"

    # Execute the curl command silently.
    JSON=$("${CURL}" -s ${API_ENDPOINT} ${CURL_ARGS} -A "TestFairy Command Line Uploader ${UPLOADER_VERSION}")

    # Extract the build URL from the JSON response.
    URL=$(echo ${JSON} | sed 's/\\\//\//g' | sed -n 's/.*"build_url"\s*:\s*"\([^"]*\)".*/\1/p')
    if [ -z "$URL" ]; then
        # Display error message if upload failed.
        echo "Error: Build uploaded but no reply from server. Please contact support@saucelabs.com"
        exit 1
    fi
    # Print the build URL if successful.
    echo "Build was successfully uploaded to TestFairy and is available at:"
    echo ${URL}
}

main "$@"
