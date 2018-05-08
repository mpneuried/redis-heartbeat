VERSIONS[4]=6
VERSIONS[5]=8
VERSIONS[5]=9
VERSIONS[5]=10
VERSIONS[6]=lts
VERSIONS[7]=latest


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTDIR="dockertests"
cd $DIR
cd ..

for version in "${VERSIONS[@]}"
do
   :
   FV=`echo $version | sed 's/\./_/'`
   DFile="Dockerfile.$FV"
   if [ -f "$SCRIPTDIR/$DFile" ]; then
	   echo "TEST Version: $version"
	   BUILDLOGS="$DIR/dockerbuild.$version.log"
	   rm -f $BUILDLOGS
	   echo "Start build ..."
	   docker build -t=mpneuried.redis-heartbeat.dockertest.$version -f=$SCRIPTDIR/$DFile . > $BUILDLOGS
	   echo "Run test ..."
	   docker run --name=mpneuried.redis-heartbeat.dockertest.$version mpneuried.redis-heartbeat.dockertest.$version >&2
	   echo "Remove container ..."
	   docker rm mpneuried.redis-heartbeat.dockertest.$version >&2
   else
	   echo "Dockerfile '$DFile' not found"
   fi
done
