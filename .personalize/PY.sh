#!/usr/bin/env bash

echo "Applying personalization for PyCharm..."

if [ -z "${PROJECT_DIRECTORY}" ]; then
  echo "ERROR: Env Var [PROJECT_DIRECTORY] is not set!"
  exit 1
fi

PYTHONPATH="${PROJECT_DIRECTORY}"
export PYTHONPATH

if command -v python3 &> /dev/null; then
  echo "Installing/Upgrading Python3 PIP and Dev resources..."
  # python3 -m pip install --upgrade pip
  apt_install python3-dev python3-pip
  PY_COMMAND=python3
elif command -v python &> /dev/null; then
  echo "Installing/Upgrading Python PIP and Dev resources..."
  # python -m pip install --upgrade pip
  apt_install python-dev python-pip
  PY_COMMAND=python
fi

if ! command -v pipx &> /dev/null; then
  echo "Installing pipx..."
  apt_install pipx
  #pipx ensurepath # Ensures that pipx is in the PATH
fi

if ! command -v virtualenv &> /dev/null; then
  echo "Installing virtualenv..."
  pipx install virtualenv
fi

if ! command -v pylint &> /dev/null; then
  echo "Installing pylint..."
  pipx install pylint
fi

echo "Creating Virtual Environment"
# virtualenv "${PROJECT_DIRECTORY}/.venv"
${PY_COMMAND} -m venv "${PROJECT_DIRECTORY}/.venv"
source "${PROJECT_DIRECTORY}/.venv/bin/activate"

if command -v pip3 &> /dev/null; then
  PIP_COMMAND=pip3
elif command -v pip &> /dev/null; then
  PIP_COMMAND=pip
else
  echo "No PIP found!"
  exit 1
fi

echo "Installing required Python packages via ${PIP_COMMAND}..."
# ${PIP_COMMAND} install -q pylint pyyaml
${PIP_COMMAND} install -q -r "${PYTHONPATH}/requirements.txt" --upgrade

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