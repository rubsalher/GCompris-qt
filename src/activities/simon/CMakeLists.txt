#=============================================================================
# Elderly-friendly build: new activity, not part of upstream GCompris.
# SPDX-License-Identifier: BSD-2-Clause
#=============================================================================
GCOMPRIS_ADD_RESOURCE(activities/simon
  QML_FILES
  *.qml
  *.js
  RESOURCES
  *.svg
  resource/*.wav
)
