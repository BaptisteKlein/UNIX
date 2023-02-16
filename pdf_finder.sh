#!/bin/bash

# Define paths and filenames
CONFIG_FILE="/home/$USER/.config/pdf_search/config"
LOG_FILE="/home/$USER/.config/pdf_search/error.log"
SEARCH_FILE="/home/$USER/.config/pdf_search/search_results.txt"

# Check if rofi is installed
if ! command -v rofi &> /dev/null
then
    echo "rofi is not installed. Please install rofi to use the search interface."
    exit 1
fi

# Define functions
search_pdf() {
    keyword="$1"
    rg --color=never --line-number --no-heading "$keyword" $(grep -v "^#" $CONFIG_FILE) | cut -d ":" -f 1,2 > $SEARCH_FILE
}

open_pdf() {
    pdf_file="$1"
    evince "$pdf_file"
}

search_history() {
    cat $LOG_FILE | rofi -dmenu -i -p "Search history:" | xargs -I{} search_pdf "{}"
}

# Check if config file exists and is readable
if [ ! -r "$CONFIG_FILE" ]
then
    echo "Error: Config file not found or cannot be read." >> $LOG_FILE
    exit 1
fi

# Get search keyword from user input using rofi
keyword=$(rofi -dmenu -i -p "Search for:")

# Check if search keyword is empty
if [ -z "$keyword" ]
then
    exit 0
fi

# Search for keyword in PDF files
search_pdf "$keyword"

# Check if search was successful
if [ ! -s "$SEARCH_FILE" ]
then
    echo "No results found for \"$keyword\"" >> $LOG_FILE
    exit 0
fi

# Present search results in rofi
pdf_file=$(cut -d ":" -f 1 $SEARCH_FILE | rofi -dmenu -i -p "Results for \"$keyword\":")

# Open selected PDF file
if [ -n "$pdf_file" ]
then
    open_pdf "$pdf_file"
fi

# Ask user if they want to search again or view search history
while true
do
    options=("Search again" "Search history" "Quit")
    choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Choose an option:")

    case $choice in
        "Search again")
            keyword=$(rofi -dmenu -i -p "Search for:")
            if [ -n "$keyword" ]
            then
                search_pdf "$keyword"
                if [ -s "$SEARCH_FILE" ]
                then
                    pdf_file=$(cut -d ":" -f 1 $SEARCH_FILE | rofi -dmenu -i -p "Results for \"$keyword\":")
                    if [ -n "$pdf_file" ]
                    then
                        open_pdf "$pdf_file"
                    fi
                else
                    echo "No results found for \"$keyword\"" >> $LOG_FILE
                fi
            fi
            ;;
        "Search history")
            search_history
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
