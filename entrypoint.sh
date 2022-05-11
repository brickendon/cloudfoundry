#!/bin/sh
set -eu
cf_opts= 
if [ "x${INPUT_VALIDATE}" = "xfalse" ]; then
  cf_opts="--skip-ssl-validation"
fi

if [ "x${INPUT_DEBUG}" = "xtrue" ]; then
  echo "Your selected APPDIR : ${INPUT_APPDIR}"
  ls -R
fi

if [ -z ${INPUT_APPDIR+x} ]; then 
  echo "WORKDIR is not set. Staying in Root Dir"; else 
    echo ${INPUT_APPDIR}
    cd ${INPUT_APPDIR}
fi

APPLICATION_NAME=$INPUT_APPNAME

# Authenticate to Cloud Foundry
#
cf api ${INPUT_API} ${cf_opts}
CF_USERNAME=${INPUT_USERNAME} CF_PASSWORD=${INPUT_PASSWORD} cf auth

#Set the right organisation and space
#
cf target -o ${INPUT_ORG} -s ${INPUT_SPACE}

# Blue Green Deployment Method starts here
# Push the application to Cloud Foundry
#
cf push --no-start --no-route -f ${INPUT_MANIFEST} 

# Set a wait time for app to get ready.
#
echo "Waiting to ensure new app's assigned service credentials have taken effect..."
sleep 60

# Start the new app with --release tag
#
cf start ${INPUT_APPNAME}-release

# Create route for the new app with --release tag
#
for HOST in $(echo ${INPUT_HOSTNAME}); do

echo cf map-route ${APPLICATION_NAME}-release ${INPUT_DOMAIN} --hostname ${HOST}
cf map-route ${APPLICATION_NAME}-release ${INPUT_DOMAIN} --hostname ${HOST}
done

# Delete the route for the old app
# 
APP_GUID=$(cf app --guid ${APPLICATION_NAME})

ROUTE_URLS=$(cf curl /v2/apps/${APP_GUID}/route_mappings | jq -r '.resources[].entity.route_url')

for ROUTE_URL in ${ROUTE_URLS}; do
  ROUTE_DATA=$(cf curl ${ROUTE_URL} | jq '.entity')

  ROUTE_DOMAIN=$(cf curl $(echo $ROUTE_DATA | jq -r '.domain_url') | jq -r '.entity.name')

  ROUTE_HOST=$(echo $ROUTE_DATA | jq -r '.host')
  ROUTE_PATH=$(echo $ROUTE_DATA | jq -r '.path')

  echo "Unmapping ${ROUTE_HOST}.${ROUTE_DOMAIN}/${ROUTE_PATH} from ${APPLICATION_NAME}"

  cf unmap-route "${APPLICATION_NAME}" ${ROUTE_DOMAIN} --hostname "${ROUTE_HOST}" --path "${ROUTE_PATH}"
done

# Wait till the old app routes cleared
#
echo "Waiting for previous app version to process existing requests..."
sleep 60

cf stop ${APPLICATION_NAME}
cf delete -f ${APPLICATION_NAME}
cf rename ${APPLICATION_NAME}-release ${APPLICATION_NAME}

