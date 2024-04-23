#!/usr/bin/env bash

echo "Applying personalization for PyCharm..."

if [ -z "${PROJECT_DIRECTORY}" ]; then
  echo "ERROR: Env Var [PROJECT_DIRECTORY] is not set!"
  exit 1
fi

PYTHONPATH="${PROJECT_DIRECTORY}"
export PYTHONPATH

if command -v python3 &> /dev/null; then
  echo "Installing/Upgrading Python PIP..."
  python3 -m pip install --upgrade pip
elif command -v python &> /dev/null; then
  echo "Installing/Upgrading Python PIP..."
  python -m pip install --upgrade pip
fi

virtualenv "${PROJECT_DIRECTORY}/.venv" && source "${PROJECT_DIRECTORY}/.venv/bin/activate}"

if command -v pip3 &> /dev/null; then
  echo "Installing required Python packages..."
  pip3 install -q pylint pyyaml
  pip3 install -q -r "${PYTHONPATH}/requirements.txt" --upgrade
elif command -v pip &> /dev/null; then
  echo "Installing required Python packages..."
  pip install -q pylint pyyaml
  pip install -q -r "${PYTHONPATH}/requirements.txt" --upgrade
fi

# TODO: Try to get this working?
# Complains about PyCharm already running.
# Wants GUI?
#
# PYCHARM_SCRIPT="$(find ${HOME} -name pycharm.sh -type f -executable -print -quit)"
# if command -v "${PYCHARM_SCRIPT}" &> /dev/null; then
#   echo "Installing Jetbrains Plugins..."
#   pylint="com.leinardi.pycharm.pylint"                # https://plugins.jetbrains.com/plugin/11084-pylint
#   github_actions_toolbar="com.dsoftware.ghtoolbar"    # https://plugins.jetbrains.com/plugin/19347-github-actions-manager
#   env_file="net.ashald.envfile"                       # https://plugins.jetbrains.com/plugin/7861-envfile
#   ${PYCHARM_SCRIPT} installPlugins "${pylint}" "${github_actions_toolbar}" "${env_file}"
# fi