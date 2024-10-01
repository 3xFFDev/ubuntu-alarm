#!/bin/bash

FILES=()

function showBanner() {

  echo -e "\033[31m

  ####   ####  #####  ##### #  ####   ####  #          ####    ##    ####  #####
 #    # #    # #    #   #   # #      #    # #         #    #  #  #  #        #
 #      #    # #    #   #   #  ####  #    # #         #      #    #  ####    #
 #      #    # #####    #   #      # #    # #         #      ######      #   #
 #    # #    # #   #    #   # #    # #    # #         #    # #    # #    #   #
  ####   ####  #    #   #   #  ####   ####  ######     ####  #    #  ####    #

  \033[0m"

  return
}

function checkMedia() {

  for file in sounds/*.mp3; do

    if [ -f "$file" ]; then

      FILES+=("$(basename "$file")")

    fi

  done

  if [ ${#FILES[@]} -gt 0 ]; then

    echo -e "\033[31mFound ${#FILES[@]} media files.\033[0m"

  else

    echo -e "\033[31mNo media files found.\033[0m"

    exit 1

  fi

  return
}

function refreshScreen() {

  clear

  showBanner

  return
}

function alarmCaptcha() {

    num1=$((RANDOM % 900 + 100))

    num2=$((RANDOM % 900 + 100))

    if (( RANDOM % 2 )); then
        operator="+"
    else
        operator="-"
    fi

    correct_answer=$(echo "$num1 $operator $num2" | bc)

    echo -e "\033[31mSolve the following math problem to proceed:\033[0m"

    echo "$num1 $operator $num2 = ?"

    read -r user_answer

    if [[ "$user_answer" == "$correct_answer" ]]; then

        echo -e "\033[31mCorrect.\033[0m"

        return 0
    else
        echo echo -e "\033[31mIncorrect.\033[0m"

        return 1
    fi
}

function checkTrustLevel() {

    local time="$1"
    local units="$2"
    local media="$3"

    refreshScreen

    echo -e "\033[31mDo you trust yourself?\033[0m"

    actions=("Yes" "No")

    select action in "${actions[@]}"; do

        if [[ "$action" == "Yes" ]]; then

            echo "mpg123 sounds/$media" | at now + "$time $units"

            break

        elif [[ "$action" == "No" ]]; then

            for ((i = 0; i < 7; i++)); do

                if [[ "$units" == "hours" ]]; then

                    total_minutes=$((time * 60))

                    for ((i = 0; i < 7; i++)); do

                        adjusted_time=$((total_minutes + i * 10))

                        echo "mpg123 sounds/$media" | at now + "$adjusted_time minutes"

                    done
                else

                    for ((i = 0; i < 7; i++)); do

                        echo "mpg123 sounds/$media" | at now + "$((time + i * 10)) $units"
                    done
                fi
            done

            echo -e "\033[31m7 alarms scheduled with 10 minute intervals.\033[0m"

            break
        else
            echo -e "\033[31mInvalid input.\033[0m"

        fi
    done

    exit 0
}

function create() {

    refreshScreen

    echo -e "\033[31mChoose media:\033[0m"

    select media in "${FILES[@]}"; do

        if [[ -n "$media" ]]; then

          refreshScreen

            read -r -p $'\033[31mEnter time value:\033[0m ' time

            if [[ "$time" =~ ^[0-9]+$ ]]; then

              refreshScreen

                echo -e "\033[31mChoose time units:\033[0m"

                actions=("Hours" "Minutes")

                select units in "${actions[@]}"; do

                    if [[ "$units" == "Hours" ]]; then

                        checkTrustLevel "$time" "hours" "$media"

                        break

                    elif [[ "$units" == "Minutes" ]]; then

                        checkTrustLevel "$time" "minutes" "$media"

                        break

                    else
                        echo -e "\033[31mInvalid input.\033[0m"
                    fi
                done
            else
                echo -e "\033[31mInvalid input.\033[0m"
            fi
        else
            echo -e "\033[31mInvalid input.\033[0m"
        fi
    done

    return
}

function init () {

    checkMedia

    while true; do

        refreshScreen

        echo -e "\033[31mMenu:\033[0m"

        actions=("Create" "Show scheduled" "Drop scheduled" "Stop")

        select action in "${actions[@]}"; do

            if [[ "$action" == "Create" ]]; then

                create

                break

            elif [[ "$action" == "Show scheduled" ]]; then

                atq

                exit 0

            elif [[ "$action" == "Drop scheduled" ]]; then

                atq | awk '{print $1}' | while read -r job; do

                    atrm "$job"

                done

                exit 0

            elif [[ "$action" == "Stop" ]]; then

                if alarmCaptcha; then

                    pid_list=$(pgrep mpg123)

                    if [ -z "$pid_list" ]; then

                        echo -e "\033[31mNo active alarms found.\033[0m"

                    else

                        for pid in $pid_list; do

                            kill -9 "$pid"

                        done
                    fi

                    exit 0

                else
                     echo -e "\033[31mDenied.\033[0m"

                    exit 1
                fi

            else
                echo -e "\033[31mInvalid input.\033[0m"
            fi

        done

    done

    return
}

init