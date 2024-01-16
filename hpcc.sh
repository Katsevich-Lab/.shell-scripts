# Define hpcc function to pull/push from/to HPCC
function hpcc() {
  COMMAND=$1
  NAME=$2
  SUBDIR=$3
  LOCAL_DIR=$"LOCAL_"$NAME"_DATA_DIR"
  REMOTE_DIR=$"REMOTE_"$NAME"_DATA_DIR"
  if [ $COMMAND = "pull" ]
  then
    rsync -rltvP ${!REMOTE_DIR}/$SUBDIR/ ${!LOCAL_DIR}/$SUBDIR/
  fi
  if [ $COMMAND = "push" ]
  then
    rsync -rltvP ${!LOCAL_DIR}/$SUBDIR/ ${!REMOTE_DIR}/$SUBDIR/
  fi
}