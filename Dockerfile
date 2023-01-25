# build environment
# base image
FROM reactnativecommunity/react-native-android as build

# ARG NPM_REGISTRY
ARG NPM_TOKEN
# ARG MIN_VER_VERSION
# ARG DEPLOY_TO_NEXUS


# set working directory
WORKDIR /app

COPY . /app

RUN echo "registry=https://nexus.lisec.internal/repository/npm-web/" > .npmrc
RUN echo "strict-ssl=false" >> .npmrc
RUN echo "color=false" >> .npmrc
RUN echo "//$NPM_REGISTRY:_authToken=NpmToken.$NPM_TOKEN" >> .npmrc


RUN apt-get update
RUN apt-get install wget openssl

RUN wget http://cdp.lisec.com/certs/LISEC_ROOT_CA_V2.crt
RUN openssl x509 -inform DER -in LISEC_ROOT_CA_V2.crt -out /usr/local/share/ca-certificates/LISEC_ROOT_CA_V2.crt -outform PEM

RUN update-ca-certificates

RUN cd android
RUN chmod +x ./gradlew
RUN ./gradlew clean
RUN ./gradlew assembleRelease
# RUN npm version $MIN_VER_VERSION --no-git-tag-version --allow-same-version 2>&1
# RUN npm install 2>&1

# # ENV NODE_ENV=production

# RUN npm run build 2>&1

# FROM build AS testruntime
# WORKDIR /app
# RUN npm run test 2>&1

FROM scratch as testresult
COPY --from=testruntime /*.Test/TestResults ./

# FROM build AS packruntime
# ENV NODE_ENV=production

RUN echo "DEPLOY_TO_NEXUS: $DEPLOY_TO_NEXUS"
RUN if [ "$DEPLOY_TO_NEXUS" = "true" ] ; then npm publish --registry=https://$NPM_REGISTRY 2>&1 ; else echo "Skipping publish on caller request" ; fi